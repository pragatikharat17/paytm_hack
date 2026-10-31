import React, { useState } from 'react';
import { 
  Search, 
  Filter, 
  ExternalLink, 
  FileText, 
  CheckCircle2, 
  Clock, 
  AlertTriangle 
} from 'lucide-react';

export default function CaseManagement({ cases, onSelectCase }) {
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');

  const filteredCases = cases.filter((c) => {
    const matchesSearch =
      c.complaint_id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (c.payment_id && c.payment_id.toLowerCase().includes(searchTerm.toLowerCase())) ||
      c.raw_text.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesStatus = statusFilter === 'ALL' || c.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const getStatusBadge = (status) => {
    switch (status) {
      case 'AUTO_RESOLVED':
        return 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30';
      case 'APPROVED':
        return 'bg-emerald-500/15 text-emerald-300 border-emerald-500/30';
      case 'PENDING_APPROVAL':
        return 'bg-amber-500/15 text-amber-400 border-amber-500/30';
      case 'ESCALATED':
        return 'bg-rose-500/15 text-rose-400 border-rose-500/30';
      default:
        return 'bg-slate-700/40 text-slate-300 border-slate-600';
    }
  };

  return (
    <div className="space-y-6">
      {/* Header and Controls */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-extrabold text-white">Resolution Case Management</h2>
          <p className="text-xs text-slate-400 mt-1">
            Browse all ingested complaints, multi-agent decisions, and automated refund references.
          </p>
        </div>

        <div className="flex items-center gap-3">
          {/* Search Box */}
          <div className="relative">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search by Case, Payment, text..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="bg-navy-900 border border-navy-700 rounded-xl pl-9 pr-4 py-2 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-teal-500 w-64"
            />
          </div>

          {/* Status Filter */}
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="bg-navy-900 border border-navy-700 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-teal-500 font-medium"
          >
            <option value="ALL">All Statuses ({cases.length})</option>
            <option value="AUTO_RESOLVED">Auto Resolved</option>
            <option value="PENDING_APPROVAL">Pending Approval</option>
            <option value="APPROVED">Approved</option>
            <option value="ESCALATED">Escalated</option>
          </select>
        </div>
      </div>

      {/* Cases Table */}
      <div className="rounded-2xl border border-navy-700 bg-navy-900 overflow-hidden shadow-xl">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-slate-300">
            <thead className="bg-navy-950/80 text-slate-400 uppercase font-bold text-[10px] tracking-wider border-b border-navy-700">
              <tr>
                <th className="px-5 py-3.5">Case ID</th>
                <th className="px-5 py-3.5">Payment Ref</th>
                <th className="px-5 py-3.5">Amount</th>
                <th className="px-5 py-3.5">Customer Complaint</th>
                <th className="px-5 py-3.5">Lang</th>
                <th className="px-5 py-3.5">Status</th>
                <th className="px-5 py-3.5">Created</th>
                <th className="px-5 py-3.5 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-navy-800">
              {filteredCases.length === 0 ? (
                <tr>
                  <td colSpan={8} className="py-12 text-center text-slate-500 text-xs">
                    No matching resolution cases found.
                  </td>
                </tr>
              ) : (
                filteredCases.map((c) => (
                  <tr 
                    key={c.complaint_id} 
                    onClick={() => onSelectCase(c.complaint_id)}
                    className="hover:bg-navy-800/50 cursor-pointer transition"
                  >
                    <td className="px-5 py-4 font-mono font-bold text-teal-400">
                      {c.complaint_id}
                    </td>
                    <td className="px-5 py-4 font-mono text-slate-300">
                      {c.payment_id || '-'}
                    </td>
                    <td className="px-5 py-4 font-extrabold text-white">
                      {c.amount ? `₹${c.amount.toFixed(2)}` : '-'}
                    </td>
                    <td className="px-5 py-4 max-w-sm">
                      <p className="truncate text-slate-200 font-medium">{c.raw_text}</p>
                      {c.resolution_summary && (
                        <p className="text-[11px] text-slate-400 truncate mt-0.5">{c.resolution_summary}</p>
                      )}
                    </td>
                    <td className="px-5 py-4">
                      <span className="uppercase text-[10px] font-bold px-2 py-0.5 rounded bg-navy-800 text-slate-300 border border-navy-700">
                        {c.language}
                      </span>
                    </td>
                    <td className="px-5 py-4">
                      <span className={`px-2.5 py-1 rounded-full font-extrabold text-[10px] border whitespace-nowrap ${getStatusBadge(c.status)}`}>
                        {c.status}
                      </span>
                    </td>
                    <td className="px-5 py-4 text-slate-400 text-[11px] whitespace-nowrap">
                      {c.created_at ? new Date(c.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '-'}
                    </td>
                    <td className="px-5 py-4 text-right">
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          onSelectCase(c.complaint_id);
                        }}
                        className="px-2.5 py-1 rounded-lg text-teal-400 hover:text-white bg-teal-500/10 hover:bg-teal-500/20 font-semibold text-[11px] inline-flex items-center gap-1 transition"
                      >
                        Inspect <ExternalLink className="w-3 h-3" />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
