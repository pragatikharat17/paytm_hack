import React from 'react';
import { 
  Users, 
  CheckCircle2, 
  Clock, 
  AlertTriangle, 
  TrendingUp,
  Cpu,
  ArrowRight,
  ShieldCheck,
  Zap
} from 'lucide-react';

export default function Overview({ kpis, cases, approvals, onSelectCase, onNavigateApprovals }) {
  const cards = [
    {
      title: 'Total Ingested Complaints',
      value: kpis?.total_complaints ?? 0,
      subtext: 'Multilingual Voice & Text',
      icon: Users,
      color: 'text-teal-400',
      bg: 'bg-teal-500/10',
      border: 'border-teal-500/20',
    },
    {
      title: 'Autonomous Resolutions',
      value: kpis?.resolved_cases ?? 0,
      subtext: 'Instant verified refunds',
      icon: CheckCircle2,
      color: 'text-emerald-400',
      bg: 'bg-emerald-500/10',
      border: 'border-emerald-500/20',
    },
    {
      title: 'Pending Supervisor Sign-offs',
      value: kpis?.pending_approvals ?? 0,
      subtext: 'Exceeds autonomous limit',
      icon: Clock,
      color: 'text-amber-400',
      bg: 'bg-amber-500/10',
      border: 'border-amber-500/20',
      action: onNavigateApprovals,
    },
    {
      title: 'Escalated Fraud / Disputes',
      value: kpis?.escalated_cases ?? 0,
      subtext: 'Routed to Tier-2 desk',
      icon: AlertTriangle,
      color: 'text-rose-400',
      bg: 'bg-rose-500/10',
      border: 'border-rose-500/20',
    },
    {
      title: 'Total Refunds Settled',
      value: `₹${(kpis?.total_refund_amount ?? 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}`,
      subtext: 'Simulated Switch Settlements',
      icon: TrendingUp,
      color: 'text-cyan-400',
      bg: 'bg-cyan-500/10',
      border: 'border-cyan-500/20',
    },
  ];

  return (
    <div className="space-y-8">
      {/* KPI Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
        {cards.map((card, i) => {
          const Icon = card.icon;
          return (
            <div
              key={i}
              onClick={card.action}
              className={`p-5 rounded-2xl bg-navy-900 border ${card.border} transition-all duration-200 hover:-translate-y-0.5 ${
                card.action ? 'cursor-pointer hover:border-amber-400' : ''
              }`}
            >
              <div className="flex items-center justify-between mb-3">
                <span className="text-xs font-semibold text-slate-400">{card.title}</span>
                <div className={`p-2 rounded-xl ${card.bg}`}>
                  <Icon className={`w-4 h-4 ${card.color}`} />
                </div>
              </div>
              <div className="text-2xl font-black text-white tracking-tight">{card.value}</div>
              <p className="text-[11px] font-medium text-slate-400 mt-1">{card.subtext}</p>
            </div>
          );
        })}
      </div>

      {/* Multi-Agent Teammate Operational Mesh */}
      <div className="p-6 rounded-2xl bg-navy-900 border border-navy-700">
        <div className="flex items-center justify-between mb-5">
          <div className="flex items-center gap-2.5">
            <Cpu className="w-5 h-5 text-teal-400" />
            <h2 className="text-base font-bold text-white">Multi-Agent Teammate Operational Mesh</h2>
          </div>
          <span className="text-xs px-2.5 py-1 rounded-full bg-teal-500/10 text-teal-400 border border-teal-500/30 font-semibold flex items-center gap-1.5">
            <Zap className="w-3.5 h-3.5" />
            Active Real-Time Pipeline
          </span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-5 gap-3">
          <div className="p-4 rounded-xl bg-navy-950/60 border border-navy-800">
            <span className="text-xs font-bold text-teal-400 block mb-1">Agent 1: Orchestrator</span>
            <p className="text-xs text-slate-300 font-medium">Intent Classifier & Router</p>
            <p className="text-[11px] text-slate-400 mt-1">Ingests Marathi, Hindi, & English</p>
          </div>
          <div className="p-4 rounded-xl bg-navy-950/60 border border-navy-800">
            <span className="text-xs font-bold text-cyan-400 block mb-1">Agent 2: Transaction</span>
            <p className="text-xs text-slate-300 font-medium">Ledger & Gateway Audit</p>
            <p className="text-[11px] text-slate-400 mt-1">Checks bank debit & switch logs</p>
          </div>
          <div className="p-4 rounded-xl bg-navy-950/60 border border-navy-800">
            <span className="text-xs font-bold text-amber-400 block mb-1">Agent 3: Policy & Risk</span>
            <p className="text-xs text-slate-300 font-medium">Deterministic Rule Engine</p>
            <p className="text-[11px] text-slate-400 mt-1">₹1,000 threshold & fraud limits</p>
          </div>
          <div className="p-4 rounded-xl bg-navy-950/60 border border-navy-800">
            <span className="text-xs font-bold text-emerald-400 block mb-1">Agent 4: Resolution</span>
            <p className="text-xs text-slate-300 font-medium">Action & Verification</p>
            <p className="text-[11px] text-slate-400 mt-1">Executes & verifies settlement</p>
          </div>
          <div className="p-4 rounded-xl bg-navy-950/60 border border-navy-800">
            <span className="text-xs font-bold text-purple-400 block mb-1">Agent 5: Case Memory</span>
            <p className="text-xs text-slate-300 font-medium">Deduplication & Learning</p>
            <p className="text-[11px] text-slate-400 mt-1">Blocks duplicate refund requests</p>
          </div>
        </div>
      </div>

      {/* Two-Column Layout: Pending Approvals & Live Cases */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Urgent Supervisor Approvals */}
        <div className="p-6 rounded-2xl bg-navy-900 border border-navy-700 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-bold text-white text-sm flex items-center gap-2">
                <Clock className="w-4 h-4 text-amber-400" />
                Urgent Approvals Required ({approvals?.length ?? 0})
              </h3>
              <button 
                onClick={onNavigateApprovals} 
                className="text-xs font-semibold text-teal-400 hover:text-teal-300 flex items-center gap-1"
              >
                View Queue <ArrowRight className="w-3.5 h-3.5" />
              </button>
            </div>

            {(!approvals || approvals.length === 0) ? (
              <div className="py-8 text-center text-slate-400 text-xs bg-navy-950/40 rounded-xl border border-navy-800">
                <CheckCircle2 className="w-6 h-6 text-emerald-400 mx-auto mb-2" />
                All pending approvals cleared! Safe autonomous operations.
              </div>
            ) : (
              <div className="space-y-3">
                {approvals.slice(0, 3).map((a) => (
                  <div 
                    key={a.approval_id}
                    onClick={onNavigateApprovals}
                    className="p-3.5 rounded-xl bg-navy-950/60 border border-amber-500/30 hover:border-amber-400 transition cursor-pointer flex items-center justify-between"
                  >
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-bold text-white">{a.approval_id}</span>
                        <span className="text-[10px] px-2 py-0.5 rounded bg-amber-500/20 text-amber-300 font-semibold">
                          Risk: {((a.risk_score || 0) * 100).toFixed(0)}%
                        </span>
                      </div>
                      <p className="text-xs text-slate-400 mt-0.5 line-clamp-1">{a.reason}</p>
                    </div>
                    <div className="text-right">
                      <span className="text-sm font-extrabold text-amber-400">₹{a.amount.toFixed(2)}</span>
                      <span className="block text-[10px] text-slate-400 font-medium">Needs Sign-off</span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Live Ingested Complaints */}
        <div className="p-6 rounded-2xl bg-navy-900 border border-navy-700">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold text-white text-sm flex items-center gap-2">
              <ShieldCheck className="w-4 h-4 text-teal-400" />
              Recent Resolution Cases
            </h3>
            <span className="text-xs text-slate-400">Click to inspect evidence</span>
          </div>

          <div className="space-y-2.5">
            {cases.slice(0, 4).map((c) => {
              const isResolved = c.status === 'AUTO_RESOLVED' || c.status === 'APPROVED';
              const isPending = c.status === 'PENDING_APPROVAL';
              const isEscalated = c.status === 'ESCALATED';

              return (
                <div
                  key={c.complaint_id}
                  onClick={() => onSelectCase(c.complaint_id)}
                  className="p-3.5 rounded-xl bg-navy-950/50 hover:bg-navy-800 border border-navy-800 hover:border-teal-500/40 transition cursor-pointer flex items-center justify-between"
                >
                  <div className="min-w-0 pr-3">
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-bold text-teal-400">{c.complaint_id}</span>
                      {c.payment_id && (
                        <span className="text-[11px] text-slate-400 font-mono font-medium">
                          ({c.payment_id})
                        </span>
                      )}
                      <span className="text-[10px] uppercase font-bold text-slate-400">
                        [{c.language}]
                      </span>
                    </div>
                    <p className="text-xs text-slate-300 truncate mt-0.5">{c.raw_text}</p>
                  </div>
                  <div>
                    <span
                      className={`text-[10px] font-extrabold px-2.5 py-1 rounded-full whitespace-nowrap ${
                        isResolved
                          ? 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/30'
                          : isPending
                          ? 'bg-amber-500/15 text-amber-400 border border-amber-500/30'
                          : isEscalated
                          ? 'bg-rose-500/15 text-rose-400 border border-rose-500/30'
                          : 'bg-slate-700 text-slate-300'
                      }`}
                    >
                      {c.status}
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}
