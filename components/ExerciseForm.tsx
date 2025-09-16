
import React, { useState, useEffect } from 'react';
import { useAppContext } from '../context/AppContext';
import { Exercise, ExerciseType, MuscleGroup, Equipment, MovementPattern, UnitMode } from '../types';
import { EXERCISE_TYPES, MUSCLE_GROUPS, EQUIPMENT_TYPES, MOVEMENT_PATTERNS, UNIT_MODES } from '../constants';
import { Button } from './ui/Button';

interface ExerciseFormProps {
  exercise: Exercise | null;
  onFinished: () => void;
}

const initialFormState: Omit<Exercise, 'id' | 'created_at' | 'updated_at' | 'is_archived'> = {
  name: '',
  type: ExerciseType.Compound,
  muscles_primary: [],
  muscles_secondary: [],
  equipment: Equipment.Barbell,
  movement_pattern: MovementPattern.Other,
  unit_mode: UnitMode.Kg,
  default_reps: 8,
  default_rest_sec: 60,
  default_weight: 20,
  notes: '',
  tempo: '',
};

export const ExerciseForm: React.FC<ExerciseFormProps> = ({ exercise, onFinished }) => {
  const { addExercise, updateExercise, exercises } = useAppContext();
  const [formData, setFormData] = useState(initialFormState);
  const [errors, setErrors] = useState<{ [key: string]: string }>({});

  useEffect(() => {
    if (exercise) {
      setFormData(exercise);
    } else {
      setFormData(initialFormState);
    }
  }, [exercise]);

  const validate = (): boolean => {
    const newErrors: { [key: string]: string } = {};
    if (formData.name.length < 2 || formData.name.length > 60) {
      newErrors.name = 'Name must be between 2 and 60 characters.';
    }
    const isNameTaken = exercises.some(ex => ex.name.toLowerCase() === formData.name.toLowerCase() && ex.id !== exercise?.id);
    if(isNameTaken) {
      newErrors.name = 'An exercise with this name already exists.';
    }
    if (formData.muscles_primary.length === 0) {
      newErrors.muscles_primary = 'At least one primary muscle must be selected.';
    }
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (validate()) {
      if (exercise) {
        updateExercise(formData as Exercise);
      } else {
        addExercise(formData);
      }
      onFinished();
    }
  };

  const handleChange = <T,>(field: keyof typeof initialFormState, value: T) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handleMultiSelectChange = (field: 'muscles_primary' | 'muscles_secondary', value: MuscleGroup) => {
    const currentSelection = formData[field] as MuscleGroup[] || [];
    const newSelection = currentSelection.includes(value)
      ? currentSelection.filter(item => item !== value)
      : [...currentSelection, value];
    handleChange(field, newSelection);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4 max-h-[70vh] overflow-y-auto pr-2">
      <div>
        <label className="block text-sm font-medium text-on-surface-secondary">Name</label>
        <input
          type="text"
          value={formData.name}
          onChange={e => handleChange('name', e.target.value)}
          className="w-full bg-background border border-border rounded-lg px-3 py-2 mt-1 focus:outline-none focus:ring-2 focus:ring-primary"
        />
        {errors.name && <p className="text-danger text-sm mt-1">{errors.name}</p>}
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium text-on-surface-secondary">Type</label>
          <select value={formData.type} onChange={e => handleChange('type', e.target.value)} className="w-full bg-background border border-border rounded-lg px-3 py-2 mt-1 focus:outline-none focus:ring-2 focus:ring-primary capitalize">
            {/* Fix: Added explicit type for 'type' in map function */}
            {EXERCISE_TYPES.map((type: ExerciseType) => <option key={type} value={type} className="capitalize">{type}</option>)}
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium text-on-surface-secondary">Equipment</label>
          <select value={formData.equipment} onChange={e => handleChange('equipment', e.target.value)} className="w-full bg-background border border-border rounded-lg px-3 py-2 mt-1 focus:outline-none focus:ring-2 focus:ring-primary capitalize">
            {/* Fix: Added explicit type for 'eq' in map function */}
            {EQUIPMENT_TYPES.map((eq: Equipment) => <option key={eq} value={eq} className="capitalize">{eq}</option>)}
          </select>
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium text-on-surface-secondary">Primary Muscles</label>
        <div className="grid grid-cols-3 gap-2 mt-1">
          {/* Fix: Added explicit type for 'muscle' in map function */}
          {MUSCLE_GROUPS.map((muscle: MuscleGroup) => (
            <button
              type="button"
              key={muscle}
              onClick={() => handleMultiSelectChange('muscles_primary', muscle)}
              className={`p-2 rounded-md text-sm capitalize transition-colors ${formData.muscles_primary.includes(muscle) ? 'bg-primary text-white' : 'bg-background hover:bg-border'}`}
            >
              {muscle}
            </button>
          ))}
        </div>
        {errors.muscles_primary && <p className="text-danger text-sm mt-1">{errors.muscles_primary}</p>}
      </div>
      
      <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-on-surface-secondary">Default Reps</label>
            <input type="number" min="1" value={formData.default_reps} onChange={e => handleChange('default_reps', parseInt(e.target.value))} className="w-full bg-background border border-border rounded-lg px-3 py-2 mt-1 focus:outline-none focus:ring-2 focus:ring-primary"/>
          </div>
          <div>
            <label className="block text-sm font-medium text-on-surface-secondary">Default Rest (sec)</label>
            <input type="number" min="0" value={formData.default_rest_sec} onChange={e => handleChange('default_rest_sec', parseInt(e.target.value))} className="w-full bg-background border border-border rounded-lg px-3 py-2 mt-1 focus:outline-none focus:ring-2 focus:ring-primary"/>
          </div>
      </div>

      <div className="pt-4 flex justify-end space-x-2">
        <Button type="button" variant="secondary" onClick={onFinished}>Cancel</Button>
        <Button type="submit">{exercise ? 'Update Exercise' : 'Create Exercise'}</Button>
      </div>
    </form>
  );
};
