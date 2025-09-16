
import React, { useState, useEffect, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAppContext } from '../context/AppContext';
// Fix: Aliased WorkoutSession type to WorkoutSessionType to avoid name conflict with the component.
import { WorkoutSession as WorkoutSessionType, SessionItem, LoggedSet, Exercise } from '../types';
import { Button } from '../components/ui/Button';

const SetRow: React.FC<{
  set: LoggedSet;
  setIndex: number;
  onUpdate: (field: keyof LoggedSet, value: any) => void;
  isCompleted: boolean;
}> = ({ set, setIndex, onUpdate, isCompleted }) => {
  return (
    <div className={`grid grid-cols-6 gap-3 items-center p-2 rounded-md ${isCompleted ? 'bg-green-100' : ''}`}>
      <span className="font-bold text-center text-on-surface">{setIndex + 1}</span>
      <div className="col-span-2 flex items-center">
        <input type="number" value={set.weight} onChange={e => onUpdate('weight', parseFloat(e.target.value))} className="w-full bg-background border border-border p-2 rounded-md text-center" />
      </div>
      <div className="col-span-2 flex items-center">
        <input type="number" value={set.reps} onChange={e => onUpdate('reps', parseInt(e.target.value))} className="w-full bg-background border border-border p-2 rounded-md text-center" />
      </div>
      <div className="text-center">
        {isCompleted ? (
            <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6 text-green-500 mx-auto" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
        ) : (
            <div className="h-6 w-6 border-2 border-border rounded-full mx-auto"></div>
        )}
      </div>
    </div>
  );
};

const ExerciseLogger: React.FC<{
  item: SessionItem;
  exercise: Exercise;
  updateSessionItem: (itemId: string, updatedSets: LoggedSet[]) => void;
}> = ({ item, exercise, updateSessionItem }) => {
  const [sets, setSets] = useState<LoggedSet[]>(item.sets);
  const completedSetsCount = sets.filter(s => s.completed_at).length;

  const updateSet = (setIndex: number, field: keyof LoggedSet, value: any) => {
    const newSets = [...sets];
    newSets[setIndex] = { ...newSets[setIndex], [field]: value };
    setSets(newSets);
    updateSessionItem(item.id, newSets);
  };
  
  const completeNextSet = () => {
      const nextSetIndex = sets.findIndex(s => !s.completed_at);
      if (nextSetIndex !== -1) {
          const newSets = [...sets];
          newSets[nextSetIndex].completed_at = new Date().toISOString();
          setSets(newSets);
          updateSessionItem(item.id, newSets);
      }
  };

  return (
    <div className="bg-surface p-4 rounded-xl border border-border shadow-sm">
      <h3 className="font-bold text-xl mb-4 text-on-surface">{exercise.name}</h3>
      <div className="grid grid-cols-6 gap-3 items-center px-2 mb-2 text-sm text-on-surface-secondary font-semibold">
        <span className="text-center">Set</span>
        <span className="col-span-2 text-center">Weight ({exercise.unit_mode})</span>
        <span className="col-span-2 text-center">Reps</span>
        <span className="text-center">Done</span>
      </div>
      <div className="space-y-2">
        {sets.map((set, index) => (
          <SetRow
            key={set.id}
            set={set}
            setIndex={index}
            onUpdate={(field, value) => updateSet(index, field, value)}
            isCompleted={!!set.completed_at}
          />
        ))}
      </div>
      <div className="mt-4">
        <Button onClick={completeNextSet} disabled={completedSetsCount === sets.length} className="w-full">
            Complete Set {completedSetsCount + 1}
        </Button>
      </div>
    </div>
  );
};


export const WorkoutSession: React.FC = () => {
    const { templateId } = useParams<{ templateId: string }>();
    const navigate = useNavigate();
    const { getTemplateById, getExerciseById, addSession } = useAppContext();
    // Fix: Use the aliased type WorkoutSessionType.
    const [session, setSession] = useState<WorkoutSessionType | null>(null);

    useEffect(() => {
        const template = getTemplateById(templateId!);
        if (template) {
            const sessionItems: SessionItem[] = template.blocks.map(block => ({
                id: `si${Date.now()}${Math.random()}`,
                exercise_id: block.exercise_id,
                sets: Array.from({ length: block.sets }, (_, i) => ({
                    id: `set${Date.now()}${Math.random()}`,
                    set_index: i,
                    weight: block.weight,
                    reps: block.reps,
                    is_warmup: false,
                    completed_at: '',
                }))
            }));

            setSession({
                id: `s${Date.now()}`,
                template_id: template.id,
                name: template.name,
                start_at: new Date().toISOString(),
                items: sessionItems,
                volume: 0,
            });
        }
        // Handle 'quick session' case later
    }, [templateId, getTemplateById]);
    
    const updateSessionItem = useCallback((itemId: string, updatedSets: LoggedSet[]) => {
        setSession(prev => {
            if (!prev) return null;
            return {
                ...prev,
                items: prev.items.map(item => item.id === itemId ? {...item, sets: updatedSets} : item)
            }
        });
    }, []);

    const finishSession = () => {
        if (session) {
            // Fix: Use the aliased type WorkoutSessionType.
            const finalSession: WorkoutSessionType = {
                ...session,
                end_at: new Date().toISOString(),
                duration_sec: (new Date().getTime() - new Date(session.start_at).getTime()) / 1000,
                volume: session.items.reduce((totalVol, item) => {
                    return totalVol + item.sets.reduce((itemVol, set) => {
                        return itemVol + (set.completed_at ? set.weight * set.reps : 0);
                    }, 0);
                }, 0),
            };
            addSession(finalSession);
            navigate('/');
        }
    };

    if (!session) {
        return <div className="text-center p-8">Loading session...</div>;
    }

    return (
        <div className="max-w-3xl mx-auto space-y-6 pb-20">
            <div className="flex justify-between items-center">
                <h1 className="text-3xl font-bold text-on-surface">{session.name}</h1>
                <Button variant="danger" onClick={finishSession}>End Session</Button>
            </div>
            <div className="space-y-6">
                {session.items.map(item => {
                    const exercise = getExerciseById(item.exercise_id);
                    if (!exercise) return null;
                    return <ExerciseLogger key={item.id} item={item} exercise={exercise} updateSessionItem={updateSessionItem} />;
                })}
            </div>
        </div>
    );
};
