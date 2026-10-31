import React, { useState } from 'react';
import { ShieldCheck, Search, Database } from 'lucide-react';

export default function AuditTrail({ cases, onSelectCase }) {
  const [filterActor, setFilterActor] = useState('ALL');

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-extrabold text-white">System Audit & Compliance Log</h2>
          <p className="text-xs text-slate-400 mt-1">
            Complete cryptographic audit trail of every agent decision, tool execution, and supervisor sign-off.
          </p>
        </div>

        <select
          value={filterActor}
          onChange={(e) => setFilterActor(e.target.value)}
          className="bg-navy-900 border border-navy-700 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-teal-500 font-medium"
        >
          <option value="ALL">All Actors</option>
          <option value="AGENT_ORCHESTRATOR">Orchestrator Agent</option>
          <option value="AGENT_TRANSACTION">Transaction Agent</option>
          <option value="AGENT_POLICY">Policy & Risk Agent</option>
          <option value="AGENT_RESOLUTION">Resolution Agent</option>
          <option value="ADMIN">Human Supervisor</option>
          <option value="SYSTEM">Payment Switch</option>
        </select>
      </div>

      <div className="p-6 rounded-2xl bg-navy-900 border border-navy-700">
        <div className="flex items-center gap-2 mb-4 text-xs font-bold text-teal-400">
          <Database className="w-4 h-4" />
          Audit Trail Entries by Active Case
        </div>

        <div className="space-y-4">
          {cases.map((c) => (
            <div 
              key={c.complaint_id} 
              className="p-4 rounded-xl bg-navy-950/60 border border-navy-800 flex items-center justify-between hover:border-teal-500/40 transition cursor-pointer"
              onClick={() => onSelectCase(c.complaint_id)}
            >
              <div>
                <div className="flex items-center gap-2">
                  <span className="font-mono text-xs font-bold text-teal-400">{c.complaint_id}</span>
                  <span className="text-xs text-slate-300">Payment: <strong>{c.payment_id || 'N/A'}</strong></span>
                  <span className="text-[10px] px-2 py-0.5 rounded bg-navy-800 text-slate-400">
                    Status: {c.status}
                  </span>
                </div>
                <p className="text-xs text-slate-400 mt-1 truncate max-w-xl">
                  {c.raw_text}
                </p>
              </div>

              <button 
                onClick={(e) => {
                  e.stopPropagation();
                  onSelectCase(c.complaint_id);
                }}
                className="px-3 py-1.5 rounded-lg bg-teal-500/10 text-teal-400 font-bold text-xs hover:bg-teal-500/20 transition"
              >
                View Full Audit Logs
              </button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
