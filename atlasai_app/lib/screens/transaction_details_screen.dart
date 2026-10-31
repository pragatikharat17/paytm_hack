import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'ai_assistant_screen.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final String paymentId;
  final PaymentItem? initialPayment;

  const TransactionDetailsScreen({
    super.key,
    required this.paymentId,
    this.initialPayment,
  });

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  PaymentItem? _payment;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialPayment != null) {
      _payment = widget.initialPayment;
      _isLoading = false;
    } else {
      _loadPayment();
    }
  }

  Future<void> _loadPayment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final p = await ApiService().fetchPayment(widget.paymentId);
      setState(() {
        _payment = p;
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
        title: Text('Payment ${widget.paymentId}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPayment),
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
                    onPressed: _loadPayment,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final p = _payment!;
    final isFailed = p.status == 'FAILED';
    final isSuccess = p.status == 'SUCCESS';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount & Status Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isFailed
                    ? [AppTheme.surfaceTint, const Color(0xFFFFE9ED)]
                    : isSuccess
                    ? [AppTheme.surfaceTint, const Color(0xFFE3F6ED)]
                    : [AppTheme.surfaceTint, AppTheme.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isFailed
                    ? AppTheme.roseDanger.withValues(alpha: 0.4)
                    : AppTheme.borderSubtle,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      p.paymentId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.cyanAccent,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isFailed
                            ? AppTheme.roseDanger.withValues(alpha: 0.2)
                            : isSuccess
                            ? AppTheme.emeraldSuccess.withValues(alpha: 0.2)
                            : AppTheme.amberWarning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        p.status,
                        style: TextStyle(
                          color: isFailed
                              ? AppTheme.roseDanger
                              : isSuccess
                              ? AppTheme.emeraldSuccess
                              : AppTheme.amberWarning,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '₹${p.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Method: ${p.method} • Order: ${p.orderId}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Diagnostic Switch & Bank Status
          const Text(
            'Payment Gateway Diagnostics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              children: [
                _buildDiagnosticRow(
                  'Gateway Switch Status',
                  p.gatewayStatus,
                  icon: Icons.alt_route,
                  color: p.gatewayStatus == 'SUCCESS'
                      ? AppTheme.emeraldSuccess
                      : AppTheme.roseDanger,
                ),
                const Divider(color: AppTheme.borderSubtle, height: 24),
                _buildDiagnosticRow(
                  'Bank Account Debit',
                  p.bankStatus,
                  icon: Icons.account_balance,
                  color: p.bankStatus == 'DEBITED'
                      ? AppTheme.amberWarning
                      : AppTheme.emeraldSuccess,
                ),
                if (p.bankRef != null) ...[
                  const Divider(color: AppTheme.borderSubtle, height: 24),
                  _buildDiagnosticRow(
                    'Bank Reference / RRN',
                    p.bankRef!,
                    icon: Icons.tag,
                    color: AppTheme.cyanAccent,
                  ),
                ],
                if (p.failureReason != null) ...[
                  const Divider(color: AppTheme.borderSubtle, height: 24),
                  _buildDiagnosticRow(
                    'Failure Reason',
                    p.failureReason!,
                    icon: Icons.info_outline,
                    color: AppTheme.roseDanger,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Action Button: Raise Dispute
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AIAssistantScreen(
                      initialPrompt:
                          'My payment ${p.paymentId} for ₹${p.amount.toInt()} failed. Please investigate and refund.',
                      paymentIdHint: p.paymentId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.support_agent, color: Colors.black),
              label: const Text(
                'Resolve with AtlasAI Teammate',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tealPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticRow(
    String label,
    String value, {
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
