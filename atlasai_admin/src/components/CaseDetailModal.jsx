import React from 'react';
import { 
  X, 
  ShieldCheck, 
  Cpu, 
  CreditCard, 
  ArrowRight, 
  FileText, 
  Clock, 
  AlertTriangle,
  Receipt,
  UserCheck
} from 'lucide-react';

export default function CaseDetailModal({ detail, onClose, onApprove, onReject }) {
  if (!detail) return null;

  const { complaint, customer, payment, order, refund, approval, ticket, audit_logs, agent_decisions } = detail;

  const isResolved = complaint.status === 'AUTO_RESOLVED' || complaint.status === 'APPROVED';
  const isPending = complaint.status === 'PENDING_APPROVAL';
  const isEscalated = complaint.status === 'ESCALATED';

  return (
    <div className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-navy-900 border border-navy-700 rounded-2xl max-w-4xl w-full max-h-[90vh] flex flex-col shadow-2xl overflow-hidden">
        {/* Modal Header */}
        <div className="px-6 py-4 border-b border-navy-700 flex items-center justify-between bg-navy-950/60">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-teal-500/20 text-teal-400 flex items-center justify-center font-mono font-bold text-xs">
              AI
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-base font-extrabold text-white">Case Evidence: {complaint.complaint_id}</h3>
                <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-extrabold border ${
                  isResolved
                    ? 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30'
                    : isPending
                    ? 'bg-amber-500/15 text-amber-400 border-amber-500/30'
                    : isEscalated
                    ? 'bg-rose-500/15 text-rose-400 border-rose-500/30'
                    : 'bg-slate-700 text-slate-300'
                }`}>
                  {complaint.status}
                </span>
              </div>
              <p className="text-xs text-slate-400">
                Created {new Date(complaint.created_at).toLocaleString()} • Language: {complaint.original_language?.toUpperCase()}
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-navy-800 transition"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Body - Scrollable */}
        <div className="p-6 overflow-y-auto space-y-6">
          {/* Complaint Quote */}
          <div className="p-4 rounded-xl bg-navy-950/80 border border-navy-800">
            <span className="text-[11px] font-bold uppercase tracking-wider text-teal-400 block mb-1">
              Customer Complaint Ingested
            </span>
            <p className="text-sm text-slate-100 font-medium italic">
              "{complaint.raw_text}"
            </p>
            {complaint.translated_text && complaint.translated_text !== complaint.raw_text && (
              <p className="text-xs text-slate-400 mt-2 font-sans not-italic border-t border-navy-800 pt-2">
                <strong>English Normalization:</strong> {complaint.translated_text}
              </p>
            )}
            {complaint.resolution_summary && (
              <div className="mt-3 pt-3 border-t border-navy-800">
                <span className="text-[11px] font-bold text-slate-300">Final Teammate Decision:</span>
                <p className="text-xs text-emerald-400 mt-0.5">{complaint.resolution_summary}</p>
              </div>
            )}
          </div>

          {/* Payment & Gateway Evidence */}
          {payment && (
            <div>
              <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-2 flex items-center gap-1.5">
                <CreditCard className="w-3.5 h-3.5 text-teal-400" />
                Simulated Payment Gateway Diagnostics
              </h4>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                <div className="p-3 rounded-xl bg-navy-950/50 border border-navy-800">
                  <span className="text-[11px] text-slate-400 block">Payment ID</span>
                  <span className="text-xs font-mono font-bold text-white">{payment.payment_id}</span>
                </div>
                <div className="p-3 rounded-xl bg-navy-950/50 border border-navy-800">
                  <span className="text-[11px] text-slate-400 block">Amount</span>
                  <span className="text-xs font-bold text-teal-400">₹{payment.amount.toFixed(2)}</span>
                </div>
                <div className="p-3 rounded-xl bg-navy-950/50 border border-navy-800">
                  <span className="text-[11px] text-slate-400 block">Switch Status</span>
                  <span className={`text-xs font-bold ${payment.gateway_status === 'SUCCESS' ? 'text-emerald-400' : 'text-rose-400'}`}>
                    {payment.gateway_status}
                  </span>
                </div>
                <div className="p-3 rounded-xl bg-navy-950/50 border border-navy-800">
                  <span className="text-[11px] text-slate-400 block">Bank Account Debit</span>
                  <span className="text-xs font-bold text-amber-400">{payment.bank_status}</span>
                </div>
              </div>
              {payment.bank_ref && (
                <p className="text-xs text-slate-400 mt-2 font-mono">
                  Bank Reference UTR: <strong className="text-slate-200">{payment.bank_ref}</strong>
                </p>
              )}
            </div>
          )}

          {/* Multi-Agent Reasoning Chain */}
          <div>
            <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-2 flex items-center gap-1.5">
              <Cpu className="w-3.5 h-3.5 text-teal-400" />
              Autonomous Multi-Agent Reasoning Log
            </h4>
            <div className="space-y-2.5">
              {agent_decisions && agent_decisions.length > 0 ? (
                agent_decisions.map((ad, idx) => (
                  <div key={idx} className="p-3.5 rounded-xl bg-navy-950/60 border border-navy-800">
                    <div className="flex items-center justify-between mb-1">
                      <span className="text-xs font-bold text-teal-400">{ad.agent_name}</span>
                      <span className="text-[10px] px-2 py-0.5 rounded bg-teal-500/10 text-teal-300 font-semibold">
                        Decision: {ad.decision}
                      </span>
                    </div>
                    <p className="text-xs text-slate-300">{ad.reasoning}</p>
                    {ad.tools_called && (
                      <div className="mt-2 text-[11px] font-mono text-slate-400 bg-navy-900 p-2 rounded border border-navy-800">
                        Tools Executed: {JSON.stringify(ad.tools_called)}
                      </div>
                    )}
                  </div>
                ))
              ) : (
                <p className="text-xs text-slate-500 italic">No agent trace recorded for this record.</p>
              )}
            </div>
          </div>

          {/* Settlement / Refund Details */}
          {refund && (
            <div className="p-4 rounded-xl bg-emerald-500/10 border border-emerald-500/30">
              <div className="flex items-center justify-between mb-2">
                <span className="text-xs font-bold text-emerald-400 flex items-center gap-1.5">
                  <Receipt className="w-4 h-4" />
                  Verified Reversal Settlement Confirmation
                </span>
                <span className="text-xs font-extrabold text-emerald-400">{refund.status}</span>
              </div>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-2 text-xs">
                <div>
                  <span className="text-slate-400">Refund ID:</span>{' '}
                  <strong className="text-white font-mono">{refund.refund_id}</strong>
                </div>
                <div>
                  <span className="text-slate-400">Amount:</span>{' '}
                  <strong className="text-emerald-400">₹{refund.amount.toFixed(2)}</strong>
                </div>
                <div>
                  <span className="text-slate-400">Bank Switch Ref:</span>{' '}
                  <strong className="text-white font-mono">{refund.gateway_refund_ref || 'VERIFIED_SWITCH'}</strong>
                </div>
              </div>
            </div>
          )}

          {/* Audit Trail Timeline */}
          {audit_logs && audit_logs.length > 0 && (
            <div>
              <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-2 flex items-center gap-1.5">
                <Clock className="w-3.5 h-3.5 text-slate-400" />
                Immutable Audit Trail ({audit_logs.length} Events)
              </h4>
              <div className="rounded-xl border border-navy-800 bg-navy-950/40 p-3 space-y-2 max-h-48 overflow-y-auto">
                {audit_logs.map((log, i) => (
                  <div key={i} className="flex items-start gap-2.5 text-xs text-slate-300 border-b border-navy-900 pb-2 last:border-0 last:pb-0">
                    <span className="text-slate-500 font-mono text-[10px] whitespace-nowrap pt-0.5">
                      {new Date(log.timestamp).toLocaleTimeString()}
                    </span>
                    <span className="font-bold text-teal-400 whitespace-nowrap">[{log.actor}]</span>
                    <div className="flex-1">
                      <strong className="text-white">{log.action}</strong>
                      {log.details && (
                        <p className="text-[11px] text-slate-400 font-mono mt-0.5 truncate">
                          {JSON.stringify(log.details)}
                        </p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Modal Footer */}
        <div className="px-6 py-4 border-t border-navy-700 bg-navy-950/60 flex items-center justify-between">
          <div className="text-xs text-slate-400">
            {isPending && <span className="text-amber-400 font-bold">Action Required: Approval needed in Supervisor Queue</span>}
          </div>
          <button
            onClick={onClose}
            className="px-4 py-2 rounded-xl text-xs font-bold text-white bg-navy-800 hover:bg-navy-700 transition"
          >
            Close Evidence Window
          </button>
        </div>
      </div>
    </div>
  );
}
