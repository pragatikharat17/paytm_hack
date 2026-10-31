import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../models/complaint_model.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'ai_assistant_screen.dart';
import 'transaction_details_screen.dart';
import 'complaint_tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PaymentItem> _payments = [];
  List<ComplaintItem> _complaints = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final payments = await ApiService().fetchPayments();
      final complaints = await ApiService().fetchComplaints();
      if (!mounted) return;
      setState(() {
        _payments = payments;
        _complaints = complaints;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Home data load failed: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Unable to connect. Check your connection and tap refresh to retry.';
        _isLoading = false;
      });
    }
  }

  final _paymentsKey = GlobalKey();
  final _casesKey = GlobalKey();

  void _openAssistant({String? prompt, String? paymentId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AIAssistantScreen(initialPrompt: prompt, paymentIdHint: paymentId),
      ),
    );
  }

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: 16,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFEDE5FA),
              foregroundColor: Color(0xFF7041A6),
              child: Text('AI', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AtlasAI Paytm',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.brandBlue,
                    ),
                  ),
                  Text(
                    'Your payment companion',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Transactions',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  110 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroCard(),
                    const SizedBox(height: 20),
                    _section(
                      title: 'Payments & Support',
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final count =
                              constraints.maxWidth < 280 ||
                                  MediaQuery.textScalerOf(context).scale(1) >
                                      1.3
                              ? 2
                              : 4;
                          final items = [
                            _service(
                              'File Dispute',
                              Icons.chat_bubble_outline_rounded,
                              () => _openAssistant(),
                            ),
                            _service(
                              'Voice Assistant',
                              Icons.mic_none_rounded,
                              () => _openAssistant(),
                            ),
                            _service(
                              'Payment History',
                              Icons.receipt_long_outlined,
                              () => _scrollTo(_paymentsKey),
                            ),
                            _service(
                              'Track Cases',
                              Icons.assignment_outlined,
                              () => _scrollTo(_casesKey),
                            ),
                          ];
                          return Wrap(
                            spacing: 8,
                            runSpacing: 20,
                            children: items
                                .map(
                                  (item) => SizedBox(
                                    width:
                                        (constraints.maxWidth -
                                            (count - 1) * 8) /
                                        count,
                                    child: item,
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _section(
                      title: 'Explore Resolution Demos',
                      subtitle: 'Try a simulated payment issue',
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _demoCard(
                              'Quick refund',
                              '₹499',
                              'Failed payment',
                              Icons.currency_rupee_rounded,
                              const Color(0xFFE2F6ED),
                              '₹499 was deducted, but my payment failed. Please refund my money. (PAY1001)',
                              'PAY1001',
                            ),
                            const SizedBox(width: 10),
                            _demoCard(
                              'Approval review',
                              '₹1,299',
                              'Higher-value refund',
                              Icons.verified_user_outlined,
                              const Color(0xFFFFF6DA),
                              "My ₹1,299 payment failed. I haven't received my refund. (PAY1002)",
                              'PAY1002',
                            ),
                            const SizedBox(width: 10),
                            _demoCard(
                              'Report a payment',
                              '₹899',
                              'Unrecognized charge',
                              Icons.shield_outlined,
                              const Color(0xFFFDE9ED),
                              "I don't recognize this ₹899 transaction. This might be unauthorized fraud! (PAY1003)",
                              'PAY1003',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCEF2FA),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.record_voice_over_outlined,
                            size: 32,
                            color: AppTheme.brandBlue,
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Help in your language',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'English • हिंदी • मराठी',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _openAssistant(),
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppTheme.brandBlue,
                            ),
                            tooltip: 'Open multilingual assistant',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      key: _paymentsKey,
                      child: _section(
                        title: 'Recent Payments',
                        subtitle: '${_payments.length} transactions',
                        child: Column(
                          children: [
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.cloud_off_outlined,
                                      size: 18,
                                      color: AppTheme.textMuted,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_payments.isEmpty)
                              _buildEmptyState(
                                'Your payments will appear here.',
                              )
                            else
                              ..._payments.map(_buildPaymentCard),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      key: _casesKey,
                      child: _section(
                        title: 'Your Support Cases',
                        child: Column(
                          children: [
                            if (_complaints.isEmpty)
                              _buildEmptyState(
                                _errorMessage != null
                                    ? 'Connect to load your support cases.'
                                    : 'No cases yet. We’re here when you need us.',
                              )
                            else
                              ..._complaints.take(4).map(_buildComplaintCard),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'Built for simpler payment support',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0875CE), Color(0xFF002970)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandBlue.withValues(alpha: 0.24),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _openAssistant(),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(
            side: BorderSide(color: Color(0xFF51B9EE)),
          ),
          icon: const Icon(Icons.auto_awesome_outlined),
          label: const Text(
            'Ask AtlasAI',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2F5FC), width: 6),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              size: 44,
              color: AppTheme.brandBlue,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment stuck?\nLet’s sort it out.',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.brandBlue,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => _openAssistant(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE84A),
                    foregroundColor: AppTheme.brandBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Get help →'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _service(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppTheme.brandBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 25),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _demoCard(
    String title,
    String amount,
    String detail,
    IconData icon,
    Color color,
    String prompt,
    String paymentId,
  ) {
    return SizedBox(
      width: 154,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openAssistant(prompt: prompt, paymentId: paymentId),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                Icon(icon, color: AppTheme.brandBlue, size: 32),
                const SizedBox(height: 12),
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.brandBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppTheme.brandBlue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(PaymentItem p) {
    final isFailed = p.status == 'FAILED';
    final isSuccess = p.status == 'SUCCESS';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionDetailsScreen(
                paymentId: p.paymentId,
                initialPayment: p,
              ),
            ),
          );
        },
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isFailed
                ? AppTheme.roseDanger.withValues(alpha: 0.15)
                : isSuccess
                ? AppTheme.emeraldSuccess.withValues(alpha: 0.15)
                : AppTheme.amberWarning.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isFailed
                ? Icons.error_outline
                : isSuccess
                ? Icons.check_circle_outline
                : Icons.hourglass_top,
            color: isFailed
                ? AppTheme.roseDanger
                : isSuccess
                ? AppTheme.emeraldSuccess
                : AppTheme.amberWarning,
            size: 22,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              p.paymentId,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                fontSize: 15,
              ),
            ),
            Text(
              '₹${p.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                fontSize: 16,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${p.method} • ${p.status}',
                style: TextStyle(
                  fontSize: 12,
                  color: isFailed ? AppTheme.roseDanger : AppTheme.textMuted,
                  fontWeight: isFailed ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const Row(
                children: [
                  Text(
                    'Details',
                    style: TextStyle(fontSize: 11, color: AppTheme.cyanAccent),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: AppTheme.cyanAccent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintCard(ComplaintItem c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ComplaintTrackingScreen(
                complaintId: c.complaintId,
                initialComplaint: c,
              ),
            ),
          );
        },
        leading: const Icon(
          Icons.assignment_outlined,
          color: AppTheme.cyanAccent,
        ),
        title: Text(
          c.complaintId,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          c.rawText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.tealPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            c.status,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.tealPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
      ),
    );
  }
}
