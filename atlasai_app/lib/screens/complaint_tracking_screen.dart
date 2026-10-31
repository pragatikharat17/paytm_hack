import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class ComplaintTrackingScreen extends StatefulWidget {
  final String complaintId;
  final ComplaintItem? initialComplaint;

  const ComplaintTrackingScreen({
    super.key,
    required this.complaintId,
    this.initialComplaint,
  });

  @override
  State<ComplaintTrackingScreen> createState() =>
      _ComplaintTrackingScreenState();
}

class _ComplaintTrackingScreenState extends State<ComplaintTrackingScreen> {
  ComplaintItem? _complaint;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialComplaint != null) {
      _complaint = widget.initialComplaint;
      _isLoading = false;
    } else {
      _loadComplaint();
    }
  }

  Future<void> _loadComplaint() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final c = await ApiService().fetchComplaint(widget.complaintId);
      setState(() {
        _complaint = c;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Case ${widget.complaintId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadComplaint,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.tealPrimary),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.roseDanger,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Error: $_error',
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadComplaint,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _buildTimelineContent(),
    );
  }

  Widget _buildTimelineContent() {
    final c = _complaint!;
    final isResolved = c.status == 'AUTO_RESOLVED' || c.status == 'APPROVED';
    final isPendingApproval = c.status == 'PENDING_APPROVAL';
    final isEscalated = c.status == 'ESCALATED';

    Color statusColor = AppTheme.amberWarning;
    if (isResolved) statusColor = AppTheme.emeraldSuccess;
    if (isEscalated) statusColor = AppTheme.roseDanger;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Case Overview Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      c.complaintId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.cyanAccent,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        c.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (c.paymentId != null)
                  Text(
                    'Linked Payment: ${c.paymentId}',
                    style: const TextStyle(
                      color: AppTheme.tealPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Original Complaint: "${c.rawText}"',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (c.resolutionSummary != null) ...[
                  const Divider(color: AppTheme.borderSubtle, height: 24),
                  const Text(
                    'Resolution Summary:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.resolutionSummary!,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Lifecycle Progression Timeline
          const Text(
            'Resolution Journey',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          _buildTimelineStep(
            title: '1. Complaint Ingested & Analyzed',
            subtitle:
                'Orchestrator Agent identified intent & language (${c.originalLanguage})',
            isDone: true,
            isCurrent: false,
          ),
          _buildTimelineStep(
            title: '2. Payment Investigation & Gateway Audit',
            subtitle:
                'Transaction Agent retrieved bank debit drop verification',
            isDone: true,
            isCurrent: false,
          ),
          _buildTimelineStep(
            title: '3. Deterministic Policy Evaluation',
            subtitle:
                'Policy & Risk Agent verified refund limits and fraud checks',
            isDone: true,
            isCurrent: isPendingApproval,
          ),
          _buildTimelineStep(
            title: isPendingApproval
                ? '4. Pending Supervisor Approval'
                : isEscalated
                ? '4. Escalated to Tier-2 Fraud Desk'
                : '4. Autonomous Reversal Settled',
            subtitle: isPendingApproval
                ? 'Awaiting human authorization for high-value transaction'
                : isEscalated
                ? 'Dispute ticket assigned to human fraud specialist'
                : 'Simulated payment switch verified instant credit',
            isDone: isResolved || isEscalated,
            isCurrent: !isResolved && !isEscalated,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? AppTheme.emeraldSuccess
                    : isCurrent
                    ? AppTheme.amberWarning
                    : AppTheme.surfaceTint,
                border: Border.all(
                  color: isDone
                      ? AppTheme.emeraldSuccess
                      : isCurrent
                      ? AppTheme.amberWarning
                      : AppTheme.borderSubtle,
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  isDone
                      ? Icons.check
                      : isCurrent
                      ? Icons.pending
                      : Icons.circle,
                  size: 14,
                  color: (isDone || isCurrent)
                      ? Colors.black
                      : AppTheme.textMuted,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 44,
                color: isDone
                    ? AppTheme.emeraldSuccess.withValues(alpha: 0.5)
                    : AppTheme.borderSubtle,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isCurrent
                      ? AppTheme.amberWarning
                      : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}
