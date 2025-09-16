import React, { useState } from 'react';
import { useAppContext } from '../context/AppContext';
import { Exercise } from '../types';
import { Modal } from '../components/ui/Modal';
import { Button } from '../components/ui/Button';
import { ExerciseForm } from '../components/ExerciseForm';
import { PlusIcon } from '../components/icons/Icons';

export const ExercisesList: React.FC = () => {
    const { exercises, updateExercise } = useAppContext();
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [selectedExercise, setSelectedExercise] = useState<Exercise | null>(null);

    const openModalForNew = () => {
        setSelectedExercise(null);
        setIsModalOpen(true);
    };

    const openModalForEdit = (exercise: Exercise) => {
        setSelectedExercise(exercise);
        setIsModalOpen(true);
    };

    const handleToggleArchive = (exercise: Exercise) => {
        updateExercise({ ...exercise, is_archived: !exercise.is_archived });
    };

    const activeExercises = exercises.filter(e => !e.is_archived);
    const archivedExercises = exercises.filter(e => e.is_archived);

    return (
        <div className="space-y-6">
            <div className="flex justify-between items-center">
                <h1 className="text-3xl font-bold text-on-surface">Exercise Library</h1>
                <Button onClick={openModalForNew}>
                    <PlusIcon className="w-5 h-5 mr-2" />
                    Add New Exercise
                </Button>
            </div>

            <div className="bg-surface p-6 rounded-xl border border-border">
                <h2 className="text-xl font-semibold text-on-surface mb-4">Active Exercises</h2>
                <div className="space-y-2">
                    {activeExercises.length > 0 ? activeExercises.map(ex => (
                        <div key={ex.id} className="flex items-center justify-between p-3 bg-background rounded-lg hover:shadow-md transition-shadow">
                            <div>
                                <p className="font-semibold text-on-surface">{ex.name}</p>
                                <p className="text-sm text-on-surface-secondary capitalize">{ex.muscles_primary.join(', ')} | {ex.equipment}</p>
                            </div>
                            <div className="flex space-x-2">
                                <Button variant="secondary" onClick={() => openModalForEdit(ex)}>Edit</Button>
                                <Button variant="tertiary" onClick={() => handleToggleArchive(ex)}>Archive</Button>
                            </div>
                        </div>
                    )) : (
                        <p className="text-on-surface-secondary text-center py-4">No active exercises. Add one to get started!</p>
                    )}
                </div>
            </div>

            {archivedExercises.length > 0 && (
                <div className="bg-surface p-6 rounded-xl border border-border">
                    <h2 className="text-xl font-semibold text-on-surface mb-4">Archived Exercises</h2>
                    <div className="space-y-2">
                        {archivedExercises.map(ex => (
                            <div key={ex.id} className="flex items-center justify-between p-3 bg-background rounded-lg opacity-60">
                                <div>
                                    <p className="font-semibold text-on-surface">{ex.name}</p>
                                    <p className="text-sm text-on-surface-secondary capitalize">{ex.muscles_primary.join(', ')} | {ex.equipment}</p>
                                </div>
                                <div className="flex space-x-2">
                                    <Button variant="secondary" onClick={() => openModalForEdit(ex)}>Edit</Button>
                                    <Button variant="tertiary" onClick={() => handleToggleArchive(ex)}>Unarchive</Button>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            )}
            
            <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={selectedExercise ? 'Edit Exercise' : 'Create New Exercise'}>
                <ExerciseForm exercise={selectedExercise} onFinished={() => setIsModalOpen(false)} />
            </Modal>
        </div>
    );
};