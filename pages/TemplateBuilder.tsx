
import React, { useState, useEffect, useMemo, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAppContext } from '../context/AppContext';
import { WorkoutTemplate, ExerciseBlock, Exercise } from '../types';
import { Button } from '../components/ui/Button';

const DraggableExerciseBlock: React.FC<{
    block: ExerciseBlock;
    index: number;
    moveBlock: (dragIndex: number, hoverIndex: number) => void;
    updateBlock: (blockId: string, field: keyof ExerciseBlock, value: any) => void;
    removeBlock: (blockId: string) => void;
}> = ({ block, index, moveBlock, updateBlock, removeBlock }) => {
    const { getExerciseById } = useAppContext();
    const exercise = getExerciseById(block.exercise_id);

    const handleDragStart = (e: React.DragEvent<HTMLDivElement>) => {
        e.dataTransfer.setData("text/plain", index.toString());
    };

    const handleDragOver = (e: React.DragEvent<HTMLDivElement>) => {
        e.preventDefault();
    };

    const handleDrop = (e: React.DragEvent<HTMLDivElement>) => {
        e.preventDefault();
        const dragIndex = parseInt(e.dataTransfer.getData("text/plain"), 10);
        moveBlock(dragIndex, index);
    };

    return (
        <div
            draggable
            onDragStart={handleDragStart}
            onDragOver={handleDragOver}
            onDrop={handleDrop}
            className="flex items-center space-x-4 bg-surface p-3 rounded-lg border border-border cursor-move"
        >
            <div className="text-on-surface-secondary">⠿</div>
            <div className="flex-1">
                <p className="font-semibold text-on-surface">{exercise?.name || 'Unknown Exercise'}</p>
                <p className="text-sm text-on-surface-secondary capitalize">{exercise?.equipment}</p>
            </div>
            <div className="flex items-center space-x-2">
                <input type="number" value={block.sets} onChange={(e) => updateBlock(block.id, 'sets', parseInt(e.target.value))} className="w-16 bg-background border border-border p-1 rounded-md text-center" />
                <span className="text-on-surface-secondary">x</span>
                <input type="number" value={block.reps} onChange={(e) => updateBlock(block.id, 'reps', parseInt(e.target.value))} className="w-16 bg-background border border-border p-1 rounded-md text-center" />
                <span className="text-on-surface-secondary">reps</span>
            </div>
             <div className="flex items-center space-x-2">
                 <input type="number" step="5" value={block.rest_sec} onChange={(e) => updateBlock(block.id, 'rest_sec', parseInt(e.target.value))} className="w-20 bg-background border border-border p-1 rounded-md text-center" />
                <span className="text-on-surface-secondary">sec rest</span>
            </div>
            <button onClick={() => removeBlock(block.id)} className="text-danger">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
            </button>
        </div>
    );
};

export const TemplateBuilder: React.FC = () => {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    const { exercises, addTemplate, updateTemplate, getTemplateById } = useAppContext();

    const [template, setTemplate] = useState<Omit<WorkoutTemplate, 'id' | 'is_archived'>>({ name: '', blocks: [], goal: 'hypertrophy' });
    const [searchTerm, setSearchTerm] = useState('');
    
    useEffect(() => {
        if (id) {
            const existingTemplate = getTemplateById(id);
            if (existingTemplate) {
                setTemplate(existingTemplate);
            }
        }
    }, [id, getTemplateById]);

    const handleAddExercise = (exercise: Exercise) => {
        const newBlock: ExerciseBlock = {
            id: `b${Date.now()}`,
            exercise_id: exercise.id,
            sets: 3,
            reps: exercise.default_reps || 8,
            weight: exercise.default_weight || 0,
            rest_sec: exercise.default_rest_sec || 60,
        };
        setTemplate(prev => ({ ...prev, blocks: [...prev.blocks, newBlock] }));
    };
    
    const updateBlock = (blockId: string, field: keyof ExerciseBlock, value: any) => {
        setTemplate(prev => ({
            ...prev,
            blocks: prev.blocks.map(b => b.id === blockId ? { ...b, [field]: value } : b)
        }));
    };

    const removeBlock = (blockId: string) => {
        setTemplate(prev => ({ ...prev, blocks: prev.blocks.filter(b => b.id !== blockId) }));
    };

    const moveBlock = useCallback((dragIndex: number, hoverIndex: number) => {
        setTemplate(prev => {
            const newBlocks = [...prev.blocks];
            const [draggedItem] = newBlocks.splice(dragIndex, 1);
            newBlocks.splice(hoverIndex, 0, draggedItem);
            return { ...prev, blocks: newBlocks };
        });
    }, []);

    const handleSave = () => {
        if (!template.name) {
            alert("Template name is required.");
            return;
        }
        if (id) {
            updateTemplate({ ...template, id, is_archived: false });
        } else {
            addTemplate(template);
        }
        navigate('/workouts');
    };
    
    const filteredExercises = useMemo(() => {
        return exercises.filter(ex => !ex.is_archived && ex.name.toLowerCase().includes(searchTerm.toLowerCase()));
    }, [exercises, searchTerm]);

    return (
        <div className="flex h-[calc(100vh-4rem)] gap-6">
            {/* Left Panel: Workout Builder */}
            <div className="w-2/3 flex flex-col space-y-4">
                <div className="flex justify-between items-center">
                    <input
                        type="text"
                        placeholder="Template Name (e.g., Push Day)"
                        value={template.name}
                        onChange={e => setTemplate(prev => ({...prev, name: e.target.value}))}
                        className="text-2xl font-bold bg-transparent border-b-2 border-border focus:outline-none focus:border-primary py-2 w-full"
                    />
                    <Button onClick={handleSave}>Save Plan</Button>
                </div>
                <div className="flex-1 bg-surface p-4 rounded-xl border border-border overflow-y-auto space-y-3">
                    {template.blocks.length === 0 ? (
                         <p className="text-center text-on-surface-secondary p-8">Add exercises from the right panel to build your workout.</p>
                    ) : (
                        template.blocks.map((block, index) => (
                           <DraggableExerciseBlock 
                                key={block.id} 
                                index={index} 
                                block={block} 
                                moveBlock={moveBlock}
                                updateBlock={updateBlock}
                                removeBlock={removeBlock}
                           />
                        ))
                    )}
                </div>
            </div>

            {/* Right Panel: Exercise Library */}
            <div className="w-1/3 flex flex-col space-y-4 bg-surface p-4 rounded-xl border border-border">
                <input
                    type="text"
                    placeholder="Search exercises..."
                    value={searchTerm}
                    onChange={e => setSearchTerm(e.target.value)}
                    className="w-full bg-background border border-border rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary"
                />
                <div className="flex-1 overflow-y-auto space-y-2 pr-2">
                    {filteredExercises.map(ex => (
                        <div key={ex.id} className="flex items-center justify-between p-2 bg-background rounded-md">
                            <div>
                                <p className="font-semibold text-on-surface">{ex.name}</p>
                                <p className="text-xs text-on-surface-secondary capitalize">{ex.equipment}</p>
                            </div>
                            <Button variant="secondary" onClick={() => handleAddExercise(ex)} className="px-2 py-1 h-8 w-8">+</Button>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
};
