import React from 'react';
import { useAppContext } from '../context/AppContext';
import * as Icons from '../components/icons/Icons';
import { useNavigate } from 'react-router-dom';
import { Button } from '../components/ui/Button';

const StatCard: React.FC<{ icon: React.ReactNode, title: string, value: string, goal?: string, color: string }> = ({ icon, title, value, goal, color }) => (
    <div className={`bg-surface p-4 rounded-xl border border-border flex items-center`}>
        <div className={`p-3 rounded-lg ${color}`}>
            {icon}
        </div>
        <div className="ml-4">
            <p className="text-sm text-on-surface-secondary">{title}</p>
            <p className="text-2xl font-bold text-on-surface">{value} <span className="text-lg font-normal text-on-surface-secondary">{goal}</span></p>
        </div>
    </div>
);

export const Dashboard: React.FC = () => {
    const { profile, sessions, getFoodLogsForDate, getSleepLogForDate, getSessionsForDate } = useAppContext();
    const navigate = useNavigate();
    const today = new Date();

    const foodLogs = getFoodLogsForDate(today);
    const totalCalories = foodLogs.reduce((sum, log) => sum + log.items.reduce((itemSum, item) => itemSum + item.calories, 0), 0);
    
    const todaysSessions = getSessionsForDate(today);
    
    const sleepLog = getSleepLogForDate(today);

    const recentSessions = [...sessions].sort((a, b) => new Date(b.start_at).getTime() - new Date(a.start_at).getTime()).slice(0, 3);
    
    return (
        <div className="space-y-6">
            <div>
                <h1 className="text-3xl font-bold text-on-surface">Welcome back, {profile.name.split(' ')[0]}!</h1>
                <p className="text-on-surface-secondary">Here's a snapshot of your wellness journey today.</p>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <StatCard icon={<Icons.CaloriesIcon className="w-6 h-6 text-white"/>} title="Calories Eaten" value={Math.round(totalCalories).toString()} goal={`/ ${profile.goals.calories} kcal`} color="bg-calories" />
                <StatCard icon={<Icons.DumbbellIcon className="w-6 h-6 text-white"/>} title="Workouts" value={todaysSessions.length.toString()} goal={todaysSessions.length > 0 ? 'Completed' : 'Planned'} color="bg-protein" />
                <StatCard icon={<Icons.SleepIcon className="w-6 h-6 text-white"/>} title="Sleep" value={sleepLog?.duration?.toString() || '0'} goal={`/ ${profile.goals.sleep} h`} color="bg-fats" />
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <div className="bg-surface p-6 rounded-xl border border-border">
                    <h2 className="text-xl font-semibold text-on-surface mb-4">Recent Workouts</h2>
                    {recentSessions.length > 0 ? (
                        <div className="space-y-3">
                            {recentSessions.map(session => (
                                <div key={session.id} className="bg-background p-3 rounded-lg flex justify-between items-center">
                                    <div>
                                        <p className="font-semibold">{session.name}</p>
                                        <p className="text-sm text-on-surface-secondary">{new Date(session.start_at).toLocaleDateString()}</p>
                                    </div>
                                    <p className="font-semibold">{Math.round(session.volume)} kg volume</p>
                                </div>
                            ))}
                        </div>
                    ) : (
                        <p className="text-on-surface-secondary text-center py-8">No recent workouts logged.</p>
                    )}
                </div>
                <div className="bg-surface p-6 rounded-xl border border-border flex flex-col items-center justify-center text-center">
                    <h2 className="text-xl font-semibold text-on-surface mb-2">Ready for today's session?</h2>
                    <p className="text-on-surface-secondary mb-4">Choose a workout plan and start tracking your progress.</p>
                    <Button onClick={() => navigate('/workouts')}>Go to Workouts</Button>
                </div>
            </div>
        </div>
    );
};
