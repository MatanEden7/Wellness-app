import React from 'react';
import { HashRouter as Router, Routes, Route, NavLink, useLocation } from 'react-router-dom';
import { AppProvider, useAppContext } from './context/AppContext';
import { Dashboard } from './pages/Dashboard';
import { Workouts } from './pages/Workouts';
import { ExercisesList } from './pages/ExercisesList';
import { TemplateBuilder } from './pages/TemplateBuilder';
import { WorkoutSession } from './pages/WorkoutSession';
import { FoodTracking } from './pages/FoodTracking';
import { SleepTracker } from './pages/SleepTracker';
import { CustomMeals } from './pages/CustomMeals';
import { Goals } from './pages/Goals';
import { Profile } from './pages/Profile';
import * as Icons from './components/icons/Icons';
import { getDayKey } from './utils/dateUtils';


const NavItem: React.FC<{ to: string; icon: React.ReactNode; children: React.ReactNode }> = ({ to, icon, children }) => {
  const location = useLocation();
  const isActive = (to === '/' && location.pathname === '/') || (to !== '/' && location.pathname.startsWith(to));
  
  const activeClass = "bg-primary-light text-primary";
  const inactiveClass = "text-on-surface-secondary hover:bg-border hover:text-on-surface";
  
  return (
    <NavLink
      to={to}
      className={`${isActive ? activeClass : inactiveClass} flex items-center p-3 rounded-lg transition-colors font-medium`}
    >
      {icon}
      <span className="ml-3">{children}</span>
    </NavLink>
  );
};

const ProgressItem: React.FC<{ icon: React.ReactNode; label: string; value: number; goal: number; unit: string; color: string; }> = ({ icon, label, value, goal, unit, color }) => {
    const percentage = goal > 0 ? Math.min((value / goal) * 100, 100) : 0;
    return (
        <div>
            <div className="flex justify-between items-center text-sm mb-1">
                <div className="flex items-center text-on-surface-secondary">
                    {icon}
                    <span className="ml-2">{label}</span>
                </div>
                <span className="font-semibold text-on-surface">{value} / {goal}{unit}</span>
            </div>
            <div className="w-full bg-border rounded-full h-1.5">
                <div className={color} style={{ width: `${percentage}%`, height: '100%', borderRadius: 'inherit' }}></div>
            </div>
        </div>
    );
};

const TodaysProgress = () => {
    const { profile, getFoodLogsForDate, getSessionsForDate, getSleepLogForDate } = useAppContext();
    const today = new Date();
    const foodLogs = getFoodLogsForDate(today);
    const sessions = getSessionsForDate(today);
    const sleepLog = getSleepLogForDate(today);

    const totalCalories = foodLogs.reduce((sum, log) => sum + log.items.reduce((itemSum, item) => itemSum + item.calories, 0), 0);

    return (
        <div className="bg-background p-3 rounded-lg space-y-3">
             <ProgressItem icon={<Icons.CaloriesIcon className="w-4 h-4 text-calories"/>} label="Calories" value={Math.round(totalCalories)} goal={profile.goals.calories} unit="" color="bg-calories" />
             <ProgressItem icon={<Icons.DumbbellIcon className="w-4 h-4 text-protein"/>} label="Workouts" value={sessions.length} goal={1} unit="" color="bg-protein" />
             <ProgressItem icon={<Icons.SleepIcon className="w-4 h-4 text-fats"/>} label="Sleep" value={sleepLog?.duration || 0} goal={profile.goals.sleep} unit="h" color="bg-fats" />
        </div>
    )
}

const navItems = [
    { to: "/", icon: <Icons.DashboardIcon className="w-6 h-6" />, label: "Dashboard" },
    { to: "/food", icon: <Icons.FoodIcon className="w-6 h-6" />, label: "Food Tracking" },
    { to: "/workouts", icon: <Icons.WorkoutIcon className="w-6 h-6" />, label: "Workouts" },
    { to: "/workout-plans", icon: <Icons.WorkoutPlanIcon className="w-6 h-6" />, label: "Workout Plans" },
    { to: "/sleep", icon: <Icons.SleepIcon className="w-6 h-6" />, label: "Sleep Tracker" },
    { to: "/custom-meals", icon: <Icons.CustomMealIcon className="w-6 h-6" />, label: "Custom Meals" },
    { to: "/goals", icon: <Icons.GoalIcon className="w-6 h-6" />, label: "Goals" },
    { to: "/profile", icon: <Icons.ProfileIcon className="w-6 h-6" />, label: "Profile" },
]

const AppLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const { profile } = useAppContext();
    return (
        <div className="flex h-screen bg-background text-on-surface">
            <aside className="w-72 bg-surface p-4 border-r border-border flex flex-col fixed h-full">
                <div className="flex items-center mb-8 px-2">
                    <div className="bg-primary p-2 rounded-lg">
                        <Icons.LogoIcon className="w-7 h-7 text-white" />
                    </div>
                    <div className="ml-3">
                        <h1 className="text-xl font-bold text-on-surface">FitTracker</h1>
                        <p className="text-xs text-on-surface-secondary">Your Complete Wellness Hub</p>
                    </div>
                </div>

                <p className="text-xs font-semibold text-on-surface-secondary uppercase mb-2 px-3">Navigation</p>
                <nav className="flex-grow space-y-1">
                    {navItems.map(item => <NavItem key={item.to} to={item.to} icon={item.icon}>{item.label}</NavItem>)}
                </nav>

                <div className="mt-auto">
                     <p className="text-xs font-semibold text-on-surface-secondary uppercase mb-2 px-3">Today's Progress</p>
                     <TodaysProgress />
                     <div className="border-t border-border my-4"></div>
                     <div className="flex items-center">
                        <div className="w-10 h-10 rounded-full bg-primary-light flex items-center justify-center text-primary font-bold">
                            {profile.name.charAt(0)}
                        </div>
                        <div className="ml-3">
                            <p className="font-semibold text-sm text-on-surface">{profile.name}</p>
                            <p className="text-xs text-on-surface-secondary">Transform・Progress・Excel</p>
                        </div>
                     </div>
                </div>
            </aside>
            <main className="flex-1 p-8 overflow-y-auto ml-72">
                {children}
            </main>
        </div>
    );
};


const App = () => {
  return (
    <AppProvider>
      <Router>
        <AppLayout>
            <Routes>
                <Route path="/" element={<Dashboard />} />
                <Route path="/workouts" element={<Workouts />} />
                <Route path="/exercises" element={<ExercisesList />} />
                <Route path="/workout-plans" element={<TemplateBuilder />} />
                <Route path="/workout-plans/edit/:id" element={<TemplateBuilder />} />
                <Route path="/session/:templateId" element={<WorkoutSession />} />
                <Route path="/food" element={<FoodTracking />} />
                <Route path="/sleep" element={<SleepTracker />} />
                <Route path="/custom-meals" element={<CustomMeals />} />
                <Route path="/goals" element={<Goals />} />
                <Route path="/profile" element={<Profile />} />
            </Routes>
        </AppLayout>
      </Router>
    </AppProvider>
  );
};

export default App;