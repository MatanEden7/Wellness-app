
export enum UnitMode {
  Kg = 'kg',
  Lbs = 'lbs',
}

export enum ExerciseType {
  Compound = 'compound',
  Isolation = 'isolation',
  Cardio = 'cardio',
  Stretching = 'stretching',
}

export enum MuscleGroup {
  Chest = 'chest',
  Back = 'back',
  Shoulders = 'shoulders',
  Biceps = 'biceps',
  Triceps = 'triceps',
  Quads = 'quads',
  Hamstrings = 'hamstrings',
  Glutes = 'glutes',
  Calves = 'calves',
  Abs = 'abs',
  Forearms = 'forearms',
  Traps = 'traps',
  Lats = 'lats',
}

export enum Equipment {
  Barbell = 'barbell',
  Dumbbell = 'dumbbell',
  Kettlebell = 'kettlebell',
  Machine = 'machine',
  Cable = 'cable',
  Bodyweight = 'bodyweight',
  Bands = 'bands',
  Other = 'other',
}

export enum MovementPattern {
  HorizontalPress = 'horizontal press',
  VerticalPress = 'vertical press',
  HorizontalPull = 'horizontal pull',
  VerticalPull = 'vertical pull',
  Squat = 'squat',
  Hinge = 'hinge',
  Lunge = 'lunge',
  Isolation = 'isolation',
  Carry = 'carry',
  Other = 'other',
}

export interface Exercise {
  id: string;
  created_at?: string;
  updated_at?: string;
  name: string;
  type: ExerciseType;
  muscles_primary: MuscleGroup[];
  muscles_secondary: MuscleGroup[];
  equipment: Equipment;
  movement_pattern: MovementPattern;
  unit_mode: UnitMode;
  default_reps: number;
  default_rest_sec: number;
  default_weight: number;
  notes?: string;
  tempo?: string;
  is_archived: boolean;
}

export interface ExerciseBlock {
  id: string;
  exercise_id: string;
  exerciseName?: string;
  sets: number;
  reps: number;
  weight: number;
  rest_sec: number;
}

export interface WorkoutTemplate {
  id: string;
  name: string;
  goal: string;
  notes?: string;
  blocks: ExerciseBlock[];
  is_archived: boolean;
}

export interface LoggedSet {
    id: string;
    set_index: number;
    weight: number;
    reps: number;
    is_warmup: boolean;
    completed_at: string; // ISO string
}

export interface SessionItem {
    id: string;
    exercise_id: string;
    sets: LoggedSet[];
}

export interface WorkoutSession {
    id: string;
    template_id: string; 
    name: string;
    start_at: string; // ISO string
    end_at?: string; // ISO string
    duration_sec?: number;
    volume: number;
    items: SessionItem[];
}

export interface UserProfile {
    name: string;
    age: number;
    weight: number;
    height: number;
    goals: {
        calories: number;
        protein: number;
        carbs: number;
        fats: number;
        sleep: number; // in hours
    };
}

export interface FoodItem {
    id: string;
    name: string;
    calories: number;
    protein: number;
    carbs: number;
    fats: number;
}

export interface FoodLog {
    id: string;
    date: string; // YYYY-MM-DD
    items: FoodItem[];
}

export interface SleepLog {
    id: string;
    date: string; // YYYY-MM-DD
    duration: number; // in hours
    quality: number; // 1-5
}

export interface CustomMeal {
    id: string;
    name: string;
    items: FoodItem[];
}
