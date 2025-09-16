
import React, { useState } from 'react';
import { generateWorkoutPlan } from '../services/geminiService';
import { useAppContext } from '../context/AppContext';
import { EQUIPMENT_TYPES } from '../constants';
import { Modal } from './ui/Modal';
import { Button } from './ui/Button';
import { BotIcon } from './icons/Icons';
import { useNavigate } from 'react-router-dom';
import { Equipment } from '../types';

export const AIGeneratorModal: React.FC = () => {
  const { addTemplate, exercises } = useAppContext();
  const navigate = useNavigate();
  const [isOpen, setIsOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [goal, setGoal] = useState('hypertrophy');
  const [experience, setExperience] = useState('intermediate');
  const [equipment, setEquipment] = useState<string[]>(['barbell', 'dumbbell']);

  const handleEquipmentChange = (item: string) => {
    setEquipment(prev =>
      prev.includes(item) ? prev.filter(i => i !== item) : [...prev, item]
    );
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);
    try {
      const newTemplate = await generateWorkoutPlan(goal, experience, equipment, exercises);
      addTemplate(newTemplate);
      setIsLoading(false);
      setIsOpen(false);
      alert('AI Workout Template Generated! You can find it in your workouts list.');
      navigate('/workouts');
    } catch (err: any) {
      setError(err.message || 'An unknown error occurred.');
      setIsLoading(false);
    }
  };

  return (
    <>
      <Button onClick={() => setIsOpen(true)}>
        <BotIcon className="w-5 h-5 mr-2" />
        Generate with AI
      </Button>

      <Modal isOpen={isOpen} onClose={() => setIsOpen(false)} title="Generate Workout with AI">
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-on-surface-secondary">Primary Goal</label>
            <select value={goal} onChange={e => setGoal(e.target.value)} className="w-full bg-background border border-border rounded-lg px-3 py-2 mt-1 focus:outline-none focus:ring-2 focus:ring-primary capitalize">
              <option value="hypertrophy">Hypertrophy (Muscle Growth)</option>
              <option value="strength">Strength</option>
              <option value="endurance">Endurance</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-on-surface-secondary">Experience Level</label>
            <select value={experience} onChange={e => setExperience(e.target.value)} className="w-full bg-background border border-border rounded-lg px-3 py-2 mt-1 focus:outline-none focus:ring-2 focus:ring-primary capitalize">
              <option value="beginner">Beginner</option>
              <option value="intermediate">Intermediate</option>
              <option value="advanced">Advanced</option>
            </select>
          </div>
          
          <div>
            <label className="block text-sm font-medium text-on-surface-secondary">Available Equipment</label>
            <div className="grid grid-cols-3 gap-2 mt-1">
                {/* Fix: Added explicit type for 'item' in map function */}
                {EQUIPMENT_TYPES.map((item: Equipment) => (
                    <button
                        type="button"
                        key={item}
                        onClick={() => handleEquipmentChange(item)}
                        className={`p-2 rounded-md text-sm capitalize transition-colors ${equipment.includes(item) ? 'bg-primary text-white' : 'bg-background hover:bg-border'}`}
                    >
                        {item}
                    </button>
                ))}
            </div>
          </div>

          {error && <p className="text-danger text-sm">{error}</p>}

          <div className="pt-4 flex justify-end">
            <Button type="submit" disabled={isLoading}>
              {isLoading ? 'Generating...' : 'Generate Plan'}
            </Button>
          </div>
        </form>
      </Modal>
    </>
  );
};
