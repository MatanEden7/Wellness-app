import React, { useState, useEffect } from 'react';
import { useAppContext } from '../context/AppContext';
import { UserProfile } from '../types';
import { Button } from '../components/ui/Button';

export const Profile: React.FC = () => {
    const { profile, updateProfile } = useAppContext();
    const [formData, setFormData] = useState<UserProfile>(profile);
    const [isSaved, setIsSaved] = useState(false);

    useEffect(() => {
        setFormData(profile);
    }, [profile]);

    const handleChange = (field: keyof UserProfile, value: any) => {
        setFormData(prev => ({ ...prev, [field]: value }));
    };
    
    const handleGoalChange = (field: keyof UserProfile['goals'], value: any) => {
        setFormData(prev => ({
            ...prev,
            goals: { ...prev.goals, [field]: value }
        }));
    };

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        updateProfile(formData);
        setIsSaved(true);
        setTimeout(() => setIsSaved(false), 2000);
    };

    return (
        <div className="max-w-4xl mx-auto space-y-6">
            <h1 className="text-3xl font-bold text-on-surface">Profile & Settings</h1>
            
            <form onSubmit={handleSubmit} className="bg-surface p-6 rounded-xl border border-border space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                        <label className="block text-sm font-medium text-on-surface-secondary">Name</label>
                        <input type="text" value={formData.name} onChange={e => handleChange('name', e.target.value)} className="w-full bg-background border border-border rounded-lg px-3 py-2 mt-1"/>
                    </div>
                     <div>
                        <label className="block text-sm font-medium text-on-surface-secondary">Age</label>
                        <input type="number" value={formData.age} onChange={e => handleChange('age', parseInt(e.target.value))} className="w-full bg-background border border-border rounded-lg px-3 py-2 mt-1"/>
                    </div>
                     <div>
                        <label className="block text-sm font-medium text-on-surface-secondary">Weight (kg)</label>
                        <input type="number" value={formData.weight} onChange={e => handleChange('weight', parseFloat(e.target.value))} className="w-full bg-background border border-border rounded-lg px-3 py-2 mt-1"/>
                    </div>
                     <div>
                        <label className="block text-sm font-medium text-on-surface-secondary">Height (cm)</label>
                        <input type="number" value={formData.height} onChange={e => handleChange('height', parseFloat(e.target.value))} className="w-full bg-background border border-border rounded-lg px-3 py-2 mt-1"/>
                    </div>
                </div>

                <h2 className="text-xl font-bold border-t border-border pt-4">Daily Goals</h2>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
                     <div>
                        <label className="block text-sm font-medium text-on-surface-secondary">Calories</label>
                        <input type="number" value={formData.goals.calories} onChange={e => handleGoalChange('calories', parseInt(e.target.value))} className="w-full bg-background border border-border rounded-lg px-3 py-2 mt-1"/>
                    </div>
                     <div>
                        <label className="block text-sm font-medium text-on-surface-secondary">Protein (g)</label>
                        <input type="number" value={formData.goals.protein} onChange={e => handleGoalChange('protein', parseInt(e.target.value))} className="w-full bg-background border border-border rounded-lg px-3 py-2 mt-1"/>
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-on-surface-secondary">Carbs (g)</label>
                        <input type="number" value={formData.goals.carbs} onChange={e => handleGoalChange('carbs', parseInt(e.target.value))} className="w-full bg-background border border-border rounded-lg px-3 py-2 mt-1"/>
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-on-surface-secondary">Fats (g)</label>
                        <input type="number" value={formData.goals.fats} onChange={e => handleGoalChange('fats', parseInt(e.target.value))} className="w-full bg-background border border-border rounded-lg px-3 py-2 mt-1"/>
                    </div>
                </div>

                <div className="flex justify-end items-center">
                    {isSaved && <p className="text-green-600 mr-4">Profile saved!</p>}
                    <Button type="submit">Save Changes</Button>
                </div>
            </form>
        </div>
    );
};
