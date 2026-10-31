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
      setState(() {
        _payments = payments;
        _complaints = complaints;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyBackground,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.tealPrimary,
              ),
              child: const Icon(Icons.bolt, size: 18, color: Colors.black87),
            ),
            const SizedBox(width: 10),
            const Text(
              'AtlasAI Paytm',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Transactions',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.tealPrimary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.tealPrimary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.roseDanger.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.roseDanger.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppTheme.roseDanger, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Backend connection warning: $_errorMessage. Running in offline/demo mode.',
                                style: const TextStyle(fontSize: 12, color: AppTheme.roseDanger),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Welcome & Hero Card
                    _buildHeroCard(),
                    const SizedBox(height: 24),

                    // Hackathon Demo Scenarios Shortcut Bar
                    _buildDemoScenariosSection(),
                    const SizedBox(height: 28),

                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: 28),

                    // Recent Payments
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Payments',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                        Text(
                          '${_payments.length} Records',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_payments.isEmpty)
                      _buildEmptyState('No simulated payments found.')
                    else
                      ..._payments.map((p) => _buildPaymentCard(p)),

                    const SizedBox(height: 28),

                    // Recent Resolution Cases
                    if (_complaints.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Active Cases & Disputes',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                          Text(
                            '${_complaints.length} Cases',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._complaints.take(4).map((c) => _buildComplaintCard(c)),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
          );
        },
        backgroundColor: AppTheme.tealPrimary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('AI Resolution Teammate', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Autonomous Agent Ready',
                  style: TextStyle(color: AppTheme.cyanAccent, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(Icons.shield_outlined, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Instant Payment\nResolution Engine',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Autonomous refunds, multi-agent investigations & multilingual voice support in Hindi & Marathi.',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoScenariosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hackathon Demo Scenarios',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.cyanAccent),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildScenarioChip(
                label: 'Scenario A: ₹499 Auto-Refund',
                scenarioPrompt: '₹499 was deducted, but my payment failed. Please refund my money. (PAY1001)',
                paymentId: 'PAY1001',
                color: AppTheme.emeraldSuccess,
              ),
              const SizedBox(width: 10),
              _buildScenarioChip(
                label: 'Scenario B: ₹1,299 Admin Approval',
                scenarioPrompt: "My ₹1,299 payment failed. I haven't received my refund. (PAY1002)",
                paymentId: 'PAY1002',
                color: AppTheme.amberWarning,
              ),
              const SizedBox(width: 10),
              _buildScenarioChip(
                label: 'Scenario C: ₹899 Fraud Dispute',
                scenarioPrompt: "I don't recognize this ₹899 transaction. This might be unauthorized fraud! (PAY1003)",
                paymentId: 'PAY1003',
                color: AppTheme.roseDanger,
              ),
              const SizedBox(width: 10),
              _buildScenarioChip(
                label: 'Scenario D: Marathi / Hindi Voice',
                scenarioPrompt: 'माझे ₹499 खात्यातून कट झाले पण पेमेंट अयशस्वी झाले. कृपया रिफंड करा. (PAY1001)',
                paymentId: 'PAY1001',
                color: AppTheme.cyanAccent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScenarioChip({
    required String label,
    required String scenarioPrompt,
    required String paymentId,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AIAssistantScreen(
              initialPrompt: scenarioPrompt,
              paymentIdHint: paymentId,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.navyCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            title: 'File Dispute',
            subtitle: 'AI Agent Help',
            icon: Icons.chat_bubble_outline,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            title: 'Voice Assistant',
            subtitle: 'Hindi / Marathi',
            icon: Icons.mic_none,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AIAssistantScreen(
                    initialPrompt: '₹499 कट गए लेकिन पेमेंट फेल हो गया, मेरा रिफंड कब आएगा? PAY1001',
                    paymentIdHint: 'PAY1001',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.tealPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.tealPrimary, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ],
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
        color: AppTheme.navyCard,
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
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 15),
            ),
            Text(
              '₹${p.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary, fontSize: 16),
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
                  Text('Details', style: TextStyle(fontSize: 11, color: AppTheme.cyanAccent)),
                  Icon(Icons.chevron_right, size: 14, color: AppTheme.cyanAccent),
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
        color: AppTheme.navyElevated,
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
        leading: const Icon(Icons.assignment_outlined, color: AppTheme.cyanAccent),
        title: Text(
          c.complaintId,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
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
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.tealPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
    );
  }
}
