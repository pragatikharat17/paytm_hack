import React, { useState } from 'react';
import { Play, Sparkles, CheckCircle2, Clock, AlertTriangle, Globe } from 'lucide-react';
import { api } from '../services/api';

export default function DemoScenarios({ onScenarioRunComplete }) {
  const [runningScenario, setRunningScenario] = useState(null);
  const [latestResult, setLatestResult] = useState(null);

  const scenarios = [
    {
      id: 'A',
      title: 'Scenario A: Autonomous Instant Refund',
      amount: '₹499.00',
      expected: 'AUTO_RESOLVED (COMPLETED)',
      prompt: '₹499 was deducted, but my payment failed. Please refund my money. (PAY1001)',
      paymentId: 'PAY1001',
      lang: 'en',
      color: 'border-emerald-500/40 text-emerald-400',
      badge: 'bg-emerald-500/10 text-emerald-400',
      icon: CheckCircle2,
      desc: 'Failed payment below the ₹1,000 autonomous threshold. Verified against gateway switch and instantly credited back.',
    },
    {
      id: 'B',
      title: 'Scenario B: Sensitive Value Admin Approval',
      amount: '₹1,299.00',
      expected: 'PENDING_APPROVAL (Supervisor Required)',
      prompt: "My ₹1,299 payment failed. I haven't received my refund. (PAY1002)",
      paymentId: 'PAY1002',
      lang: 'en',
      color: 'border-amber-500/40 text-amber-400',
      badge: 'bg-amber-500/10 text-amber-400',
      icon: Clock,
      desc: 'Failed payment of ₹1,299 exceeds autonomous threshold. Pauses in Supervisor Approval Queue awaiting human authorization.',
    },
    {
      id: 'C',
      title: 'Scenario C: Unrecognized Charge & Dispute',
      amount: '₹899.00',
      expected: 'ESCALATED (Fraud Dispute Ticket)',
      prompt: "I don't recognize this ₹899 transaction. This might be unauthorized fraud! (PAY1003)",
      paymentId: 'PAY1003',
      lang: 'en',
      color: 'border-rose-500/40 text-rose-400',
      badge: 'bg-rose-500/10 text-rose-400',
      icon: AlertTriangle,
      desc: 'Customer flags suspicious transaction. Risk engine flags high fraud score and creates a priority Tier-2 ticket.',
    },
    {
      id: 'D',
      title: 'Scenario D: Multilingual Voice (Hindi/Marathi)',
      amount: '₹499.00',
      expected: 'Sarvam NLU, Translation & Bulbul TTS',
      prompt: 'माझे ₹499 खात्यातून कट झाले पण पेमेंट अयशस्वी झाले. कृपया रिफंड करा. (PAY1001)',
      paymentId: 'PAY1001',
      lang: 'mr',
      color: 'border-cyan-500/40 text-cyan-400',
      badge: 'bg-cyan-500/10 text-cyan-400',
      icon: Globe,
      desc: 'Regional language complaint in Marathi processed via Sarvam AI, normalized for reasoning, and translated with speech synthesis.',
    },
  ];

  const handleRun = async (scenario) => {
    setRunningScenario(scenario.id);
    setLatestResult(null);

    try {
      const result = await api.resolveComplaint(scenario.prompt, scenario.paymentId, scenario.lang);
      setLatestResult({
        scenarioId: scenario.id,
        result,
      });
      if (onScenarioRunComplete) onScenarioRunComplete();
    } catch (err) {
      alert(`Scenario execution failed: ${err.message}`);
    } finally {
      setRunningScenario(null);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-extrabold text-white">Hackathon Demo Scenario Runner</h2>
        <p className="text-xs text-slate-400 mt-1">
          Trigger real autonomous multi-agent pipelines on simulated transactions PAY1001–PAY1004.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {scenarios.map((s) => {
          const Icon = s.icon;
          const isRunning = runningScenario === s.id;

          return (
            <div
              key={s.id}
              className={`p-5 rounded-2xl bg-navy-900 border ${s.color} flex flex-col justify-between shadow-xl`}
            >
              <div>
                <div className="flex items-center justify-between mb-2">
                  <span className={`px-2.5 py-0.5 rounded-full text-[11px] font-extrabold border ${s.badge}`}>
                    {s.title}
                  </span>
                  <span className="text-xs font-mono font-bold text-white">{s.amount}</span>
                </div>

                <p className="text-xs text-slate-300 font-medium mb-3">
                  {s.desc}
                </p>

                <div className="p-3 rounded-xl bg-navy-950/70 border border-navy-800 text-xs mb-4">
                  <span className="text-[10px] uppercase font-bold text-slate-400 block mb-0.5">Prompt:</span>
                  <p className="text-slate-200 font-mono text-[11px] line-clamp-2">"{s.prompt}"</p>
                </div>
              </div>

              <div className="flex items-center justify-between pt-2 border-t border-navy-800">
                <span className="text-[11px] text-slate-400">
                  Target: <strong>{s.expected}</strong>
                </span>

                <button
                  onClick={() => handleRun(s)}
                  disabled={isRunning}
                  className="px-4 py-2 rounded-xl bg-teal-500 hover:bg-teal-400 text-black font-extrabold text-xs flex items-center gap-1.5 transition shadow-lg shadow-teal-500/20 disabled:opacity-50"
                >
                  <Play className={`w-3.5 h-3.5 fill-black ${isRunning ? 'animate-spin' : ''}`} />
                  {isRunning ? 'Running Multi-Agent Pipeline...' : 'Run Scenario'}
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {/* Latest Live Execution Trace */}
      {latestResult && (
        <div className="p-6 rounded-2xl bg-navy-900 border border-teal-500/40 shadow-2xl">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <Sparkles className="w-5 h-5 text-teal-400" />
              <h3 className="font-bold text-white text-sm">
                Scenario {latestResult.scenarioId} Execution Outcome: {latestResult.result.outcome}
              </h3>
            </div>
            <span className="text-xs text-slate-400">
              Confidence: {((latestResult.result.confidence || 1) * 100).toFixed(0)}%
            </span>
          </div>

          <div className="p-4 rounded-xl bg-navy-950/80 border border-navy-800 mb-4">
            <span className="text-[11px] font-bold text-teal-400 block mb-1">Final Teammate Message:</span>
            <p className="text-sm text-slate-100">
              {latestResult.result.translated_message || latestResult.result.final_message}
            </p>
          </div>

          {latestResult.result.refund && (
            <div className="p-3.5 rounded-xl bg-emerald-500/10 border border-emerald-500/30 text-xs mb-3 flex items-center justify-between">
              <div>
                <span className="font-bold text-emerald-400">Refund Executed & Verified:</span>{' '}
                <span className="font-mono text-white">{latestResult.result.refund.refund_id}</span> (Amount: ₹{latestResult.result.refund.amount.toFixed(2)})
              </div>
              <span className="px-2 py-0.5 rounded bg-emerald-500 text-black font-extrabold text-[10px]">
                {latestResult.result.refund.status}
              </span>
            </div>
          )}

          {latestResult.result.approval && (
            <div className="p-3.5 rounded-xl bg-amber-500/10 border border-amber-500/30 text-xs mb-3 flex items-center justify-between">
              <div>
                <span className="font-bold text-amber-400">Queued in Supervisor Approvals:</span>{' '}
                <span className="font-mono text-white">{latestResult.result.approval.approval_id}</span>
              </div>
              <span className="px-2 py-0.5 rounded bg-amber-500 text-black font-extrabold text-[10px]">
                {latestResult.result.approval.status}
              </span>
            </div>
          )}

          {latestResult.result.ticket && (
            <div className="p-3.5 rounded-xl bg-rose-500/10 border border-rose-500/30 text-xs mb-3 flex items-center justify-between">
              <div>
                <span className="font-bold text-rose-400">Escalated Dispute Ticket Created:</span>{' '}
                <span className="font-mono text-white">{latestResult.result.ticket.ticket_id}</span> (Priority: {latestResult.result.ticket.priority})
              </div>
              <span className="px-2 py-0.5 rounded bg-rose-500 text-white font-extrabold text-[10px]">
                {latestResult.result.ticket.status}
              </span>
            </div>
          )}

          <div className="pt-2">
            <span className="text-[11px] font-bold text-slate-400 block mb-2">Workflow Step Trace:</span>
            <div className="grid grid-cols-1 md:grid-cols-4 gap-2">
              {latestResult.result.workflow_steps?.map((step, idx) => (
                <div key={idx} className="p-2.5 rounded-lg bg-navy-950/60 border border-navy-800 text-[11px]">
                  <strong className="text-teal-400 block">{step.agent}</strong>
                  <span className="text-slate-300 block">{step.action}</span>
                  <span className="text-[10px] text-slate-400 block mt-0.5">{step.detail}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
