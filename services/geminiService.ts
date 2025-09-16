import { GoogleGenAI, Type } from "@google/genai";
import { WorkoutTemplate, ExerciseBlock, Exercise } from '../types';

const API_KEY = process.env.API_KEY;

if (!API_KEY) {
  console.warn("API_KEY environment variable not set. AI features will be disabled.");
}

const ai = new GoogleGenAI({ apiKey: API_KEY! });

const workoutPlanSchema = {
  type: Type.OBJECT,
  properties: {
    name: { type: Type.STRING, description: "A creative and fitting name for the workout plan." },
    goal: { type: Type.STRING, description: "The primary goal of the workout (e.g., strength, hypertrophy)." },
    notes: { type: Type.STRING, description: "A brief description of the workout plan and its focus." },
    blocks: {
      type: Type.ARRAY,
      description: "A list of exercise blocks for the workout.",
      items: {
        type: Type.OBJECT,
        properties: {
          exerciseName: { type: Type.STRING, description: "The name of the exercise." },
          sets: { type: Type.INTEGER, description: "Number of sets." },
          reps: { type: Type.INTEGER, description: "Number of repetitions per set." },
          rest_sec: { type: Type.INTEGER, description: "Rest time in seconds between sets." },
        },
        required: ["exerciseName", "sets", "reps", "rest_sec"],
      },
    },
  },
  required: ["name", "goal", "notes", "blocks"],
};

// Fix: Added a specific type for the block from the Gemini response to avoid using `any`.
interface GeminiExerciseBlock {
  exerciseName: string;
  sets: number;
  reps: number;
  rest_sec: number;
}

export const generateWorkoutPlan = async (
  goal: string,
  experience: string,
  equipment: string[],
  existingExercises: Exercise[]
): Promise<Omit<WorkoutTemplate, 'id' | 'is_archived'>> => {
  if(!API_KEY) {
    throw new Error("Gemini API key is not configured.");
  }

  const availableExercisesString = existingExercises.map(e => e.name).join(', ');

  const prompt = `
    You are a world-class strength and conditioning coach. Create a single, effective workout session for a ${experience} individual whose primary goal is ${goal}.
    
    They have access to the following equipment: ${equipment.join(', ')}.
    
    Please create a workout plan that primarily uses exercises from this list of available exercises: ${availableExercisesString}.
    If a perfect exercise from the list isn't available for a specific muscle group, you can suggest a common alternative, but prioritize the provided list.

    The response MUST be a valid JSON object that strictly adheres to the provided schema. Do not include any markdown formatting like \`\`\`json.
  `;

  try {
    const response = await ai.models.generateContent({
      model: "gemini-2.5-flash",
      contents: prompt,
      config: {
        responseMimeType: "application/json",
        responseSchema: workoutPlanSchema,
      },
    });

    const jsonString = response.text.trim();
    const parsedResult = JSON.parse(jsonString);

    const newTemplateBlocks: ExerciseBlock[] = parsedResult.blocks.map((block: GeminiExerciseBlock) => {
      const matchingExercise = existingExercises.find(ex => ex.name.toLowerCase() === block.exerciseName.toLowerCase());
      if (!matchingExercise) {
        // Here you might want to handle cases where Gemini suggests an exercise that doesn't exist.
        // For now, we'll create a placeholder ID and expect the user to resolve it.
        console.warn(`Exercise "${block.exerciseName}" not found in library. User will need to create it.`);
        return {
          id: `b${Date.now()}${Math.random()}`,
          exercise_id: 'unknown-exercise', // Special ID
          exerciseName: block.exerciseName, // Keep the name for display
          sets: block.sets,
          reps: block.reps,
          weight: 0,
          rest_sec: block.rest_sec,
        };
      }
      return {
        id: `b${Date.now()}${Math.random()}`,
        exercise_id: matchingExercise.id,
        sets: block.sets,
        reps: block.reps,
        weight: matchingExercise.default_weight || 0,
        rest_sec: matchingExercise.default_rest_sec || 60,
      };
    });
    
    const newTemplate: Omit<WorkoutTemplate, 'id' | 'is_archived'> = {
      name: parsedResult.name,
      goal: parsedResult.goal,
      notes: parsedResult.notes,
      blocks: newTemplateBlocks,
    };

    return newTemplate;

  } catch (error) {
    console.error("Error generating workout plan from Gemini:", error);
    throw new Error("Failed to generate AI workout plan. Please check your prompt and API key.");
  }
};
