import React, { useState, useEffect } from 'react';
import Sidebar from './components/Sidebar';
import Overview from './components/Overview';
import ApprovalQueue from './components/ApprovalQueue';
import CaseManagement from './components/CaseManagement';
import CaseDetailModal from './components/CaseDetailModal';
import AuditTrail from './components/AuditTrail';
import DemoScenarios from './components/DemoScenarios';
import { api } from './services/api';

export default function App() {
  const [activeTab, setActiveTab] = useState('overview');
  const [kpis, setKpis] = useState(null);
  const [cases, setCases] = useState([]);
  const [approvals, setApprovals] = useState([]);
  const [selectedCaseDetail, setSelectedCaseDetail] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [notification, setNotification] = useState(null);

  const showNotification = (msg, type = 'success') => {
    setNotification({ msg, type });
    setTimeout(() => setNotification(null), 4000);
  };

  const loadDashboardData = async () => {
    try {
      const [kpisData, casesData, approvalsData] = await Promise.all([
        api.getKPIs(),
        api.getCases(),
        api.getApprovals(),
      ]);
      setKpis(kpisData);
      setCases(casesData);
      setApprovals(approvalsData);
    } catch (err) {
      console.error('Failed to load dashboard data:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadDashboardData();
    // Auto refresh every 6 seconds
    const interval = setInterval(loadDashboardData, 6000);
    return () => clearInterval(interval);
  }, []);

  const handleSelectCase = async (complaintId) => {
    try {
      const detail = await api.getCaseDetail(complaintId);
      setSelectedCaseDetail(detail);
    } catch (err) {
      alert(`Could not load case detail: ${err.message}`);
    }
  };

  const handleApprove = async (approvalId, notes, adminName) => {
    await api.approveRequest(approvalId, notes, adminName);
    showNotification(`Approval ${approvalId} granted! Refund settlement completed & verified with payment switch.`);
    await loadDashboardData();
  };

  const handleReject = async (approvalId, notes, adminName) => {
    await api.rejectRequest(approvalId, notes, adminName);
    showNotification(`Approval ${approvalId} rejected by supervisor.`, 'error');
    await loadDashboardData();
  };

  const handleResetDb = async () => {
    if (!confirm('Reset demo transactions (PAY1001–PAY1004) to clean seed state?')) return;
    try {
      await api.resetDemoDatabase();
      showNotification('Demo transactions successfully reset to initial states.');
      await loadDashboardData();
    } catch (err) {
      alert(`Reset failed: ${err.message}`);
    }
  };

  const pendingCount = approvals.filter(a => a.status === 'PENDING').length;

  return (
    <div className="min-h-screen bg-navy-950 text-slate-100 flex">
      {/* Toast Notification */}
      {notification && (
        <div className={`fixed top-5 right-5 z-50 px-4 py-3 rounded-xl shadow-2xl text-xs font-bold border transition ${
          notification.type === 'error'
            ? 'bg-rose-500/20 text-rose-300 border-rose-500/40'
            : 'bg-emerald-500/20 text-emerald-300 border-emerald-500/40'
        }`}>
          {notification.msg}
        </div>
      )}

      {/* Fixed Sidebar */}
      <Sidebar
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        pendingCount={pendingCount}
        onResetDb={handleResetDb}
      />

      {/* Main Content Area */}
      <main className="ml-64 flex-1 p-8 max-w-7xl">
        {/* Top Header Bar */}
        <div className="flex items-center justify-between pb-6 mb-8 border-b border-navy-800">
          <div>
            <h1 className="text-2xl font-black text-white tracking-tight">
              Paytm AI Operations Console
            </h1>
            <p className="text-xs text-slate-400 mt-0.5">
              Live supervision & deterministic policy governance for Track 3: Autonomous AI Teammates
            </p>
          </div>

          <div className="flex items-center gap-3">
            <span className="text-xs font-mono px-3 py-1.5 rounded-lg bg-navy-900 border border-navy-700 text-teal-400 font-semibold">
              Supervisor: Vikram Seth
            </span>
            <button
              onClick={loadDashboardData}
              className="px-3 py-1.5 rounded-lg bg-navy-800 hover:bg-navy-700 text-xs font-semibold text-slate-200 border border-navy-700 transition"
            >
              Refresh Data
            </button>
          </div>
        </div>

        {/* Tab Views */}
        {activeTab === 'overview' && (
          <Overview
            kpis={kpis}
            cases={cases}
            approvals={approvals}
            onSelectCase={handleSelectCase}
            onNavigateApprovals={() => setActiveTab('approvals')}
          />
        )}

        {activeTab === 'approvals' && (
          <ApprovalQueue
            approvals={approvals}
            onApprove={handleApprove}
            onReject={handleReject}
            onSelectCase={handleSelectCase}
          />
        )}

        {activeTab === 'cases' && (
          <CaseManagement
            cases={cases}
            onSelectCase={handleSelectCase}
          />
        )}

        {activeTab === 'audit' && (
          <AuditTrail
            cases={cases}
            onSelectCase={handleSelectCase}
          />
        )}

        {activeTab === 'scenarios' && (
          <DemoScenarios
            onScenarioRunComplete={loadDashboardData}
          />
        )}
      </main>

      {/* Case Details Evidence Drawer */}
      <CaseDetailModal
        detail={selectedCaseDetail}
        onClose={() => setSelectedCaseDetail(null)}
        onApprove={handleApprove}
        onReject={handleReject}
      />
    </div>
  );
}
