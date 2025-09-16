
import React, { createContext, useContext, useState, ReactNode } from 'react';
import { 
    Exercise, WorkoutTemplate, WorkoutSession, UserProfile, FoodLog, SleepLog, CustomMeal,
    ExerciseType, MuscleGroup, Equipment, MovementPattern, UnitMode, FoodItem
} from '../types';
import { getDayKey } from '../utils/dateUtils';

// Mock data to initialize the application state
const MOCK_EXERCISES: Exercise[] = [
    { id: 'ex1', name: 'Barbell Bench Press', type: ExerciseType.Compound, muscles_primary: [MuscleGroup.Chest], muscles_secondary: [MuscleGroup.Shoulders, MuscleGroup.Triceps], equipment: Equipment.Barbell, movement_pattern: MovementPattern.HorizontalPress, unit_mode: UnitMode.Kg, default_reps: 8, default_rest_sec: 90, default_weight: 60, is_archived: false },
    { id: 'ex2', name: 'Barbell Squat', type: ExerciseType.Compound, muscles_primary: [MuscleGroup.Quads, MuscleGroup.Glutes], muscles_secondary: [], equipment: Equipment.Barbell, movement_pattern: MovementPattern.Squat, unit_mode: UnitMode.Kg, default_reps: 10, default_rest_sec: 120, default_weight: 80, is_archived: false },
    { id: 'ex3', name: 'Deadlift', type: ExerciseType.Compound, muscles_primary: [MuscleGroup.Back, MuscleGroup.Hamstrings, MuscleGroup.Glutes], muscles_secondary: [], equipment: Equipment.Barbell, movement_pattern: MovementPattern.Hinge, unit_mode: UnitMode.Kg, default_reps: 5, default_rest_sec: 150, default_weight: 100, is_archived: false },
    { id: 'ex4', name: 'Dumbbell Bicep Curl', type: ExerciseType.Isolation, muscles_primary: [MuscleGroup.Biceps], muscles_secondary: [], equipment: Equipment.Dumbbell, movement_pattern: MovementPattern.Isolation, unit_mode: UnitMode.Kg, default_reps: 12, default_rest_sec: 60, default_weight: 10, is_archived: false },
    { id: 'ex5', name: 'Pull Up', type: ExerciseType.Compound, muscles_primary: [MuscleGroup.Lats, MuscleGroup.Back], muscles_secondary: [MuscleGroup.Biceps], equipment: Equipment.Bodyweight, movement_pattern: MovementPattern.VerticalPull, unit_mode: UnitMode.Kg, default_reps: 8, default_rest_sec: 90, default_weight: 0, is_archived: false },
];

const MOCK_TEMPLATES: WorkoutTemplate[] = [
    {
        id: 't1', name: 'Full Body Strength', goal: 'strength', is_archived: false, blocks: [
            { id: 'b1', exercise_id: 'ex2', sets: 3, reps: 5, weight: 80, rest_sec: 120 },
            { id: 'b2', exercise_id: 'ex1', sets: 3, reps: 5, weight: 60, rest_sec: 90 },
            { id: 'b3', exercise_id: 'ex5', sets: 3, reps: 8, weight: 0, rest_sec: 90 },
        ]
    }
];

interface AppContextType {
  profile: UserProfile;
  exercises: Exercise[];
  templates: WorkoutTemplate[];
  sessions: WorkoutSession[];
  foodLogs: FoodLog[];
  sleepLogs: SleepLog[];
  customMeals: CustomMeal[];
  updateProfile: (profile: UserProfile) => void;
  addExercise: (exercise: Omit<Exercise, 'id' | 'is_archived'>) => void;
  updateExercise: (exercise: Exercise) => void;
  getExerciseById: (id: string) => Exercise | undefined;
  addTemplate: (template: Omit<WorkoutTemplate, 'id' | 'is_archived'>) => void;
  updateTemplate: (template: WorkoutTemplate) => void;
  deleteTemplate: (id: string) => void;
  getTemplateById: (id: string) => WorkoutTemplate | undefined;
  addSession: (session: WorkoutSession) => void;
  getSessionsForDate: (date: Date) => WorkoutSession[];
  addFoodLog: (date: Date, item: FoodItem) => void;
  getFoodLogsForDate: (date: Date) => FoodLog[];
  addSleepLog: (log: Omit<SleepLog, 'id'>) => void;
  getSleepLogForDate: (date: Date) => SleepLog | undefined;
  addCustomMeal: (meal: Omit<CustomMeal, 'id'>) => void;
  updateCustomMeal: (meal: CustomMeal) => void;
  deleteCustomMeal: (id: string) => void;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

const initialProfile: UserProfile = {
    name: 'Alex Doe',
    age: 30,
    weight: 80,
    height: 180,
    goals: { calories: 2500, protein: 160, carbs: 300, fats: 70, sleep: 8 }
};

export const AppProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
    const [profile, setProfile] = useState<UserProfile>(initialProfile);
    const [exercises, setExercises] = useState<Exercise[]>(MOCK_EXERCISES);
    const [templates, setTemplates] = useState<WorkoutTemplate[]>(MOCK_TEMPLATES);
    const [sessions, setSessions] = useState<WorkoutSession[]>([]);
    const [foodLogs, setFoodLogs] = useState<FoodLog[]>([]);
    const [sleepLogs, setSleepLogs] = useState<SleepLog[]>([]);
    const [customMeals, setCustomMeals] = useState<CustomMeal[]>([]);

    const updateProfile = (newProfile: UserProfile) => setProfile(newProfile);
    
    const addExercise = (exerciseData: Omit<Exercise, 'id' | 'is_archived'>) => {
        const newExercise: Exercise = { ...exerciseData, id: `ex${Date.now()}`, is_archived: false };
        setExercises(prev => [newExercise, ...prev]);
    };

    const updateExercise = (updatedExercise: Exercise) => setExercises(prev => prev.map(ex => ex.id === updatedExercise.id ? updatedExercise : ex));
    const getExerciseById = (id: string) => exercises.find(ex => ex.id === id);
    const addTemplate = (templateData: Omit<WorkoutTemplate, 'id' | 'is_archived'>) => {
        const newTemplate: WorkoutTemplate = { ...templateData, id: `t${Date.now()}`, is_archived: false };
        setTemplates(prev => [newTemplate, ...prev]);
    };
    const updateTemplate = (updatedTemplate: WorkoutTemplate) => setTemplates(prev => prev.map(t => t.id === updatedTemplate.id ? updatedTemplate : t));
    const deleteTemplate = (id: string) => setTemplates(prev => prev.filter(t => t.id !== id));
    const getTemplateById = (id: string) => templates.find(t => t.id === id);
    const addSession = (session: WorkoutSession) => setSessions(prev => [session, ...prev]);
    const getSessionsForDate = (date: Date) => {
        const key = getDayKey(date);
        return sessions.filter(s => getDayKey(new Date(s.start_at)) === key);
    };
    const addFoodLog = (date: Date, item: FoodItem) => {
        const key = getDayKey(date);
        setFoodLogs(prev => {
            const existingLog = prev.find(log => log.date === key);
            if (existingLog) {
                return prev.map(log => log.date === key ? { ...log, items: [...log.items, item] } : log);
            }
            return [...prev, { id: `fl${Date.now()}`, date: key, items: [item] }];
        });
    };
    const getFoodLogsForDate = (date: Date) => {
        const key = getDayKey(date);
        return foodLogs.filter(log => log.date === key);
    };
    const addSleepLog = (log: Omit<SleepLog, 'id'>) => {
        const newLog = { ...log, id: `sl${Date.now()}` };
        setSleepLogs(prev => prev.find(l => l.date === log.date) ? prev.map(l => l.date === log.date ? newLog : l) : [...prev, newLog]);
    };
    const getSleepLogForDate = (date: Date) => sleepLogs.find(log => log.date === getDayKey(date));
    const addCustomMeal = (meal: Omit<CustomMeal, 'id'>) => setCustomMeals(prev => [...prev, { ...meal, id: `cm${Date.now()}` }]);
    const updateCustomMeal = (updatedMeal: CustomMeal) => setCustomMeals(prev => prev.map(m => m.id === updatedMeal.id ? updatedMeal : m));
    const deleteCustomMeal = (id: string) => setCustomMeals(prev => prev.filter(m => m.id !== id));

    const value: AppContextType = { profile, exercises, templates, sessions, foodLogs, sleepLogs, customMeals, updateProfile, addExercise, updateExercise, getExerciseById, addTemplate, updateTemplate, deleteTemplate, getTemplateById, addSession, getSessionsForDate, addFoodLog, getFoodLogsForDate, addSleepLog, getSleepLogForDate, addCustomMeal, updateCustomMeal, deleteCustomMeal };

    return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
};

export const useAppContext = () => {
    const context = useContext(AppContext);
    if (context === undefined) throw new Error('useAppContext must be used within an AppProvider');
    return context;
};
