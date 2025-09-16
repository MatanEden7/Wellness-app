import React from 'react';
import { useAppContext } from '../context/AppContext';

export const History: React.FC = () => {
  const { sessions } = useAppContext();

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-on-surface">Workout History</h1>
      {sessions.length === 0 ? (
        <div className="text-center py-16 bg-surface rounded-xl border border-border">
            <h3 className="mt-2 text-xl font-semibold">No Completed Sessions</h3>
            <p className="mt-1 text-sm text-on-surface-secondary">Your completed workouts will appear here.</p>
        </div>
      ) : (
        <div className="space-y-4">
          {sessions.map(session => (
            <div key={session.id} className="bg-surface p-4 rounded-xl border border-border">
              <h2 className="font-bold text-lg">{session.name}</h2>
              <p className="text-sm text-on-surface-secondary">
                {new Date(session.start_at).toLocaleString()} - Volume: {session.volume}
              </p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
