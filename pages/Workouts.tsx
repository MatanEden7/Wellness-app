import React from 'react';
import { useNavigate } from 'react-router-dom';
import { AIGeneratorModal } from '../components/AIGeneratorModal';
import { Button } from '../components/ui/Button';
import { PlusIcon } from '../components/icons/Icons';
import { useAppContext } from '../context/AppContext';
import { WorkoutTemplate } from '../types';

const TemplateCard: React.FC<{ template: WorkoutTemplate }> = ({ template }) => {
    const { getExerciseById } = useAppContext();
    const navigate = useNavigate();
    const exercises = template.blocks.map(b => getExerciseById(b.exercise_id)?.name).filter(Boolean).slice(0, 3);

    return (
        <div className="bg-surface p-4 rounded-xl border border-border flex flex-col justify-between hover:shadow-lg transition-shadow">
            <div>
                <h3 className="font-bold text-lg text-on-surface">{template.name}</h3>
                <p className="text-sm text-on-surface-secondary capitalize mb-3">{template.goal}</p>
                <ul className="text-sm text-on-surface-secondary list-disc list-inside space-y-1">
                    {exercises.map((name, i) => <li key={i}>{name}</li>)}
                    {template.blocks.length > 3 && <li>...and more</li>}
                </ul>
            </div>
            <div className="mt-4 flex space-x-2">
                <Button onClick={() => navigate(`/session/${template.id}`)} className="flex-1">Start Session</Button>
                <Button variant="secondary" onClick={() => navigate(`/workout-plans/edit/${template.id}`)}>Edit</Button>
            </div>
        </div>
    );
};


export const Workouts: React.FC = () => {
    const { templates } = useAppContext();
    const navigate = useNavigate();
    const activeTemplates = templates.filter(t => !t.is_archived);

    return (
        <div className="space-y-6">
            <div className="flex justify-between items-center flex-wrap gap-2">
                <h1 className="text-3xl font-bold text-on-surface">Workout Plans</h1>
                <div className="flex space-x-2">
                    <AIGeneratorModal />
                    <Button variant="secondary" onClick={() => navigate('/workout-plans')}>
                         <PlusIcon className="w-5 h-5 mr-2" />
                        New Plan
                    </Button>
                     <Button variant="tertiary" onClick={() => navigate('/exercises')}>
                        Exercise Library
                    </Button>
                </div>
            </div>

            {activeTemplates.length > 0 ? (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {activeTemplates.map(template => (
                        <TemplateCard key={template.id} template={template} />
                    ))}
                </div>
            ) : (
                <div className="text-center py-16 bg-surface rounded-xl border border-border">
                    <h3 className="mt-2 text-xl font-semibold">No Workout Plans Found</h3>
                    <p className="mt-1 text-sm text-on-surface-secondary">Create your first workout plan to get started!</p>
                </div>
            )}
        </div>
    );
};