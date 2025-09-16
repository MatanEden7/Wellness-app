
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
                <