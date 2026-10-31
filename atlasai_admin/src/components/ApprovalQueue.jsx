import React, { useState } from 'react';
import { 
  CheckCircle2, 
  XCircle, 
  Clock, 
  AlertCircle, 
  ShieldAlert, 
  FileText,
  UserCheck
} from 'lucide-react';

export default function ApprovalQueue({ approvals, onApprove, onReject, onSelectCase }) {
  const [selectedApproval, setSelectedApproval] = useState(null);
  const [actionType, setActionType] = useState('approve'); // 'approve' | 'reject'
  const [notes, setNotes] = useState('');
  const [adminName, setAdminName] = useState('Vikram Seth (Support Lead)');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const pendingList = approvals.filter(a => a.status === 'PENDING');
  const pastList = approvals.filter(a => a.status !== 'PENDING');

  const openActionModal = (approval, type) => {
    setSelectedApproval(approval);
    setActionType(type);
    setNotes(
      type === 'approve'
        ? 'Verified gateway bank drop against core switch ledger. Approved instant reversal.'
        : 'Discrepancy in bank drop timestamp. Rejecting automated reversal.'
    );
  };

  const handleConfirmAction = async (e) => {
    e.preventDefault();
    if (!selectedApproval || isSubmitting) return;

    setIsSubmitting(true);
    try {
      if (actionType === 'approve') {
        await onApprove(selectedApproval.approval_id, notes, adminName);
      } else {
        await onReject(selectedApproval.approval_id, notes, adminName);
      }
      setSelectedApproval(null);
    } catch (err) {
      alert(`Action failed: ${err.message}`);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-extrabold text-white">Supervisor Approval Queue</h2>
          <p className="text-xs text-slate-400 mt-1">
            Deterministic policy guardrail: Autonomous refunds capped at ₹1,000. Higher values require human sign-off.
          </p>
        </div>
        <div className="px-3.5 py-1.5 rounded-xl bg-amber-500/10 border border-amber-500/30 flex items-center gap-2">
          <Clock className="w-4 h-4 text-amber-400" />
          <span className="text-xs font-bold text-amber-300">
            {pendingList.length} Action{pendingList.length === 1 ? '' : 's'} Pending
          </span>
        </div>
      </div>

      {/* Pending List Cards */}
      {pendingList.length === 0 ? (
        <div className="py-14 text-center bg-navy-900 border border-navy-700 rounded-2xl">
          <CheckCircle2 className="w-12 h-12 text-emerald-400 mx-auto mb-3" />
          <h3 className="text-base font-bold text-white">Zero Pending Authorizations</h3>
          <p className="text-xs text-slate-400 max-w-sm mx-auto mt-1">
            All sensitive and high-value refund requests have been evaluated and resolved.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-4">
          {pendingList.map((item) => (
            <div
              key={item.approval_id}
              className="p-5 rounded-2xl bg-navy-900 border border-amber-500/40 shadow-lg shadow-amber-500/5 transition hover:border-amber-400"
            >
              <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div className="space-y-2">
                  <div className="flex items-center gap-2.5">
                    <span className="px-2.5 py-1 rounded-lg bg-navy-800 text-teal-400 font-mono text-xs font-bold border border-navy-700">
                      {item.approval_id}
                    </span>
                    <span className="text-xs font-bold text-slate-300">
                      Case ID: <button onClick={() => onSelectCase(item.complaint_id)} className="text-teal-400 hover:underline">{item.complaint_id}</button>
                    </span>
                    <span className="px-2 py-0.5 rounded text-[11px] font-bold bg-amber-500/20 text-amber-300">
                      Role Required: {item.required_role}
                    </span>
                  </div>

                  <p className="text-sm text-slate-200 font-medium">
                    {item.reason}
                  </p>

                  <div className="flex items-center gap-4 text-xs text-slate-400">
                    <span>Risk Score: <strong className="text-slate-200">{((item.risk_score || 0) * 100).toFixed(0)}%</strong></span>
                    <span>Refund Ref: <strong className="text-slate-200">{item.refund_id || 'Generating'}</strong></span>
                  </div>
                </div>

                <div className="flex items-center gap-4">
                  <div className="text-right">
                    <span className="text-xs text-slate-400 block font-medium">Requested Refund</span>
                    <span className="text-2xl font-black text-amber-400">
                      ₹{item.amount.toFixed(2)}
                    </span>
                  </div>

                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => openActionModal(item, 'approve')}
                      className="px-4 py-2.5 rounded-xl bg-emerald-500 hover:bg-emerald-400 text-black font-bold text-xs flex items-center gap-1.5 transition shadow-md shadow-emerald-500/20"
                    >
                      <CheckCircle2 className="w-4 h-4" />
                      Approve & Settle
                    </button>
                    <button
                      onClick={() => openActionModal(item, 'reject')}
                      className="px-3.5 py-2.5 rounded-xl bg-navy-800 hover:bg-rose-900/40 text-rose-400 border border-navy-700 hover:border-rose-500/40 font-bold text-xs flex items-center gap-1.5 transition"
                    >
                      <XCircle className="w-4 h-4" />
                      Reject
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Historical Approvals Log */}
      {pastList.length > 0 && (
        <div className="pt-6">
          <h3 className="text-sm font-bold text-white mb-3">Recent Authorization Decisions</h3>
          <div className="rounded-xl border border-navy-800 bg-navy-900/60 overflow-hidden">
            <table className="w-full text-left text-xs text-slate-300">
              <thead className="bg-navy-950/70 text-slate-400 uppercase font-bold text-[10px] tracking-wider border-b border-navy-800">
                <tr>
                  <th className="px-4 py-3">Approval ID</th>
                  <th className="px-4 py-3">Case</th>
                  <th className="px-4 py-3">Amount</th>
                  <th className="px-4 py-3">Status</th>
                  <th className="px-4 py-3">Decided By</th>
                  <th className="px-4 py-3">Supervisor Notes</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-navy-800">
                {pastList.map((h) => (
                  <tr key={h.approval_id} className="hover:bg-navy-800/40 transition">
                    <td className="px-4 py-3 font-mono font-bold text-teal-400">{h.approval_id}</td>
                    <td className="px-4 py-3 font-mono">{h.complaint_id}</td>
                    <td className="px-4 py-3 font-bold text-white">₹{h.amount.toFixed(2)}</td>
                    <td className="px-4 py-3">
                      <span className={`px-2 py-0.5 rounded font-extrabold text-[10px] ${
                        h.status === 'APPROVED'
                          ? 'bg-emerald-500/20 text-emerald-300'
                          : 'bg-rose-500/20 text-rose-300'
                      }`}>
                        {h.status}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-slate-400">{h.decided_by || 'Supervisor'}</td>
                    <td className="px-4 py-3 text-slate-300 max-w-xs truncate">{h.admin_notes || '-'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Action Confirmation Modal */}
      {selectedApproval && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-navy-900 border border-navy-700 rounded-2xl max-w-lg w-full p-6 shadow-2xl">
            <div className="flex items-center gap-3 mb-4">
              <div className={`p-2.5 rounded-xl ${actionType === 'approve' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-rose-500/20 text-rose-400'}`}>
                {actionType === 'approve' ? <UserCheck className="w-6 h-6" /> : <ShieldAlert className="w-6 h-6" />}
              </div>
              <div>
                <h3 className="text-base font-bold text-white">
                  {actionType === 'approve' ? 'Authorize High-Value Refund' : 'Reject Refund Authorization'}
                </h3>
                <p className="text-xs text-slate-400">
                  Approval ID: {selectedApproval.approval_id} • Amount: ₹{selectedApproval.amount.toFixed(2)}
                </p>
              </div>
            </div>

            <form onSubmit={handleConfirmAction} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">
                  Supervisor Name / Role
                </label>
                <input
                  type="text"
                  value={adminName}
                  onChange={(e) => setAdminName(e.target.value)}
                  className="w-full bg-navy-950 border border-navy-700 rounded-xl px-3.5 py-2.5 text-xs text-white focus:outline-none focus:border-teal-500 font-medium"
                  required
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">
                  Audit Notes & Ledger Verification
                </label>
                <textarea
                  rows={3}
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  className="w-full bg-navy-950 border border-navy-700 rounded-xl p-3 text-xs text-white focus:outline-none focus:border-teal-500 font-medium resize-none"
                  placeholder="Explain why this refund is approved or rejected..."
                  required
                />
              </div>

              <div className="flex items-center justify-end gap-2.5 pt-2">
                <button
                  type="button"
                  onClick={() => setSelectedApproval(null)}
                  className="px-4 py-2.5 rounded-xl text-xs font-semibold text-slate-400 hover:text-white bg-navy-800"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className={`px-5 py-2.5 rounded-xl text-xs font-bold text-black transition ${
                    actionType === 'approve'
                      ? 'bg-emerald-400 hover:bg-emerald-300'
                      : 'bg-rose-400 hover:bg-rose-300'
                  }`}
                >
                  {isSubmitting ? 'Processing...' : actionType === 'approve' ? 'Confirm Approval & Settle' : 'Confirm Rejection'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
