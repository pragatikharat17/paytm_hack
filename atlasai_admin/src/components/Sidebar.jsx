import React from 'react';
import { 
  LayoutDashboard, 
  CheckCircle2, 
  FolderGit2, 
  ShieldCheck, 
  PlayCircle,
  RotateCcw,
  Sparkles,
  Layers
} from 'lucide-react';

export default function Sidebar({ activeTab, setActiveTab, pendingCount, onResetDb }) {
  const navItems = [
    { id: 'overview', label: 'Operations Overview', icon: LayoutDashboard },
    { 
      id: 'approvals', 
      label: 'Supervisor Approvals', 
      icon: CheckCircle2,
      badge: pendingCount > 0 ? pendingCount : null,
      badgeColor: 'bg-amber-500 text-black'
    },
    { id: 'cases', label: 'Resolution Cases', icon: FolderGit2 },
    { id: 'audit', label: 'Audit Trail & Logs', icon: ShieldCheck },
    { id: 'scenarios', label: 'Demo Scenario Runner', icon: PlayCircle },
  ];

  return (
    <aside className="w-64 bg-navy-900 border-r border-navy-700 flex flex-col justify-between h-screen fixed left-0 top-0 z-20">
      <div>
        {/* Brand Header */}
        <div className="p-6 border-b border-navy-700 flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-teal-500 to-teal-400 flex items-center justify-center shadow-lg shadow-teal-500/20">
            <Sparkles className="w-6 h-6 text-black" />
          </div>
          <div>
            <h1 className="font-extrabold text-lg tracking-tight text-white flex items-center gap-1.5">
              Atlas<span className="text-teal-400">AI</span>
            </h1>
            <p className="text-xs text-slate-400 font-medium">Paytm Support Operations</p>
          </div>
        </div>

        {/* Navigation List */}
        <nav className="p-4 space-y-1.5">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id)}
                className={`w-full flex items-center justify-between px-3.5 py-3 rounded-xl text-sm font-semibold transition-all ${
                  isActive
                    ? 'bg-gradient-to-r from-teal-500/20 to-teal-500/5 text-teal-400 border border-teal-500/30'
                    : 'text-slate-400 hover:text-slate-100 hover:bg-navy-800'
                }`}
              >
                <div className="flex items-center gap-3">
                  <Icon className={`w-4 h-4 ${isActive ? 'text-teal-400' : 'text-slate-400'}`} />
                  <span>{item.label}</span>
                </div>
                {item.badge && (
                  <span className={`px-2 py-0.5 text-xs font-bold rounded-full ${item.badgeColor}`}>
                    {item.badge}
                  </span>
                )}
              </button>
            );
          })}
        </nav>
      </div>

      {/* Footer & Reset Controls */}
      <div className="p-4 border-t border-navy-700 space-y-3">
        <button
          onClick={onResetDb}
          className="w-full flex items-center justify-center gap-2 px-3 py-2.5 rounded-lg text-xs font-semibold text-slate-300 bg-navy-800 hover:bg-navy-700 hover:text-white border border-navy-600 transition"
        >
          <RotateCcw className="w-3.5 h-3.5" />
          Reset Demo Transactions
        </button>

        <div className="bg-navy-950/60 p-3 rounded-xl border border-navy-800">
          <div className="flex items-center justify-between text-xs mb-1">
            <span className="text-slate-400">Teammate Engine</span>
            <span className="inline-flex items-center gap-1 text-emerald-400 font-medium">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
              Autonomous
            </span>
          </div>
          <p className="text-[11px] text-slate-400">Track 3: Autonomous AI Teammates</p>
        </div>
      </div>
    </aside>
  );
}
