const API_BASE = '/api';

const headers = {
  'Content-Type': 'application/json',
  'x-admin-token': 'atlasai_admin_secret_2026',
};

export const api = {
  async getKPIs() {
    const res = await fetch(`${API_BASE}/admin/kpis`, { headers });
    if (!res.ok) throw new Error('Failed to fetch KPIs');
    return res.json();
  },

  async getCases(status = null) {
    let url = `${API_BASE}/admin/cases`;
    if (status) url += `?status=${encodeURIComponent(status)}`;
    const res = await fetch(url, { headers });
    if (!res.ok) throw new Error('Failed to fetch cases');
    return res.json();
  },

  async getCaseDetail(complaintId) {
    const res = await fetch(`${API_BASE}/admin/cases/${encodeURIComponent(complaintId)}`, { headers });
    if (!res.ok) throw new Error('Failed to fetch case detail');
    return res.json();
  },

  async getApprovals(status = null) {
    let url = `${API_BASE}/admin/approvals`;
    if (status) url += `?status=${encodeURIComponent(status)}`;
    const res = await fetch(url, { headers });
    if (!res.ok) throw new Error('Failed to fetch approvals');
    return res.json();
  },

  async approveRequest(approvalId, notes = '', adminName = 'Vikram Seth (Support Lead)') {
    const res = await fetch(`${API_BASE}/admin/approvals/${encodeURIComponent(approvalId)}/approve`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ admin_name: adminName, notes }),
    });
    if (!res.ok) throw new Error('Failed to approve request');
    return res.json();
  },

  async rejectRequest(approvalId, notes = '', adminName = 'Vikram Seth (Support Lead)') {
    const res = await fetch(`${API_BASE}/admin/approvals/${encodeURIComponent(approvalId)}/reject`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ admin_name: adminName, notes }),
    });
    if (!res.ok) throw new Error('Failed to reject request');
    return res.json();
  },

  async getAuditLogs(caseId) {
    const res = await fetch(`${API_BASE}/audit/${encodeURIComponent(caseId)}`, { headers });
    if (!res.ok) throw new Error('Failed to fetch audit logs');
    return res.json();
  },

  async resolveComplaint(complaintText, paymentId = null, language = 'en') {
    const res = await fetch(`${API_BASE}/agents/resolve`, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        complaint_text: complaintText,
        payment_id: paymentId,
        customer_id: 'CUST101',
        language,
      }),
    });
    if (!res.ok) throw new Error('Agent resolution pipeline failed');
    return res.json();
  },

  async resetDemoDatabase() {
    const res = await fetch(`${API_BASE}/admin/reset-demo-database`, {
      method: 'POST',
      headers,
    });
    if (!res.ok) throw new Error('Failed to reset demo database');
    return res.json();
  },
};
