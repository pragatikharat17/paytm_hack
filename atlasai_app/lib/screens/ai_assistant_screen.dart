import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/chat_message.dart';
import '../models/agent_resolution_model.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'transaction_details_screen.dart';

class AIAssistantScreen extends StatefulWidget {
  final String? initialPrompt;
  final String? paymentIdHint;

  const AIAssistantScreen({super.key, this.initialPrompt, this.paymentIdHint});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  String _selectedLanguage = 'en'; // 'en', 'hi', 'mr'
  bool _isProcessing = false;
  String _activeAgentStep = '';
  String? _currentlyPlayingId;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'label': 'English'},
    {'code': 'hi', 'label': 'हिंदी (Hindi)'},
    {'code': 'mr', 'label': 'मराठी (Marathi)'},
  ];

  @override
  void initState() {
    super.initState();
    // Add welcome message from AtlasAI
    _messages.add(
      ChatMessage(
        id: 'welcome',
        text:
            'Namaste! I am AtlasAI, your autonomous Paytm customer resolution teammate. How can I help you with your transactions or refunds today?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );

    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSend(
          prompt: widget.initialPrompt,
          paymentId: widget.paymentIdHint,
        );
      });
    }

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _currentlyPlayingId = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend({String? prompt, String? paymentId}) async {
    final text = (prompt ?? _textController.text).trim();
    if (text.isEmpty || _isProcessing) return;

    _textController.clear();

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      language: _selectedLanguage,
    );

    setState(() {
      _messages.add(userMsg);
      _isProcessing = true;
      _activeAgentStep =
          'Orchestrator Agent: Ingesting complaint & classifying intent...';
    });
    _scrollToBottom();

    // Step simulation for visual agent pipeline
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _isProcessing) {
        setState(() {
          _activeAgentStep =
              'Transaction Agent: Investigating gateway ledger & bank status...';
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && _isProcessing) {
        setState(() {
          _activeAgentStep =
              'Policy & Risk Agent: Checking refund rules & fraud thresholds...';
        });
      }
    });

    try {
      final resolution = await ApiService().resolveComplaint(
        complaintText: text,
        paymentId: paymentId,
        language: _selectedLanguage,
      );

      final assistantMsg = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: resolution.translatedMessage ?? resolution.finalMessage,
        isUser: false,
        timestamp: DateTime.now(),
        resolution: resolution,
        audioBase64: resolution.audioBase64,
        language: resolution.language,
      );

      if (mounted) {
        setState(() {
          _messages.add(assistantMsg);
          _isProcessing = false;
          _activeAgentStep = '';
        });
        _scrollToBottom();

        // Auto-play audio response if present
        if (assistantMsg.audioBase64 != null &&
            assistantMsg.audioBase64!.isNotEmpty) {
          _playAudio(assistantMsg.id, assistantMsg.audioBase64!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: 'Unable to connect to resolution teammate: $e',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isProcessing = false;
          _activeAgentStep = '';
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _playAudio(String messageId, String base64Audio) async {
    try {
      if (_currentlyPlayingId == messageId) {
        await _audioPlayer.stop();
        setState(() {
          _currentlyPlayingId = null;
        });
        return;
      }

      final bytes = base64Decode(base64Audio);
      await _audioPlayer.stop();
      await _audioPlayer.play(BytesSource(bytes));
      setState(() {
        _currentlyPlayingId = messageId;
      });
    } catch (e) {
      debugPrint('Error playing voice: $e');
    }
  }

  Future<void> _handleMicPress() async {
    // Show voice recognition modal
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _buildVoiceInputModal(ctx),
    );
  }

  Widget _buildVoiceInputModal(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 320,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sarvam AI Voice Assistant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Speak in English, Hindi, or Marathi (${_selectedLanguage.toUpperCase()})',
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () async {
              Navigator.pop(ctx);
              // Trigger voice transcription demo
              try {
                final sttRes = await ApiService().transcribeAudio(
                  languageCode: _selectedLanguage == 'hi'
                      ? 'hi-IN'
                      : _selectedLanguage == 'mr'
                      ? 'mr-IN'
                      : 'en-IN',
                );
                final transcript = sttRes['transcript'] as String? ?? '';
                if (transcript.isNotEmpty) {
                  _textController.text = transcript;
                  _handleSend(prompt: transcript);
                }
              } catch (e) {
                _textController.text =
                    '₹499 कट गए लेकिन पेमेंट फेल हो गया (PAY1001)';
                _handleSend();
              }
            },
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppTheme.tealPrimary, AppTheme.cyanAccent],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.tealPrimary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.mic, size: 36, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Tap microphone to speak or simulate voice input',
            style: TextStyle(fontSize: 12, color: AppTheme.cyanAccent),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.tealPrimary,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AtlasAI Teammate',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Autonomous Resolution Engine',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip:
                'Language: ${_languages.firstWhere((l) => l['code'] == _selectedLanguage)['label']}',
            initialValue: _selectedLanguage,
            icon: const Icon(Icons.language, color: AppTheme.cyanAccent),
            onSelected: (value) => setState(() => _selectedLanguage = value),
            itemBuilder: (_) => _languages
                .map(
                  (language) => CheckedPopupMenuItem<String>(
                    value: language['code'],
                    checked: language['code'] == _selectedLanguage,
                    child: Text(language['label']!),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Live multi-agent activity banner when processing
          if (_isProcessing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.surfaceTint,
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.cyanAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _activeAgentStep,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.cyanAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Mic button
                  IconButton(
                    onPressed: _handleMicPress,
                    icon: const Icon(Icons.mic, color: AppTheme.tealPrimary),
                    tooltip: 'Speak with Sarvam AI',
                  ),
                  const SizedBox(width: 4),

                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Describe issue or enter Payment ID...',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  IconButton.filled(
                    onPressed: _isProcessing ? null : () => _handleSend(),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.tealPrimary,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.arrow_upward, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    final res = msg.resolution;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.tealPrimary,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.tealPrimary : AppTheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.text,
                        style: TextStyle(
                          color: isUser ? Colors.black87 : AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),

                      // Audio playback controls if voice response exists
                      if (msg.audioBase64 != null &&
                          msg.audioBase64!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () => _playAudio(msg.id, msg.audioBase64!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceTint,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.cyanAccent.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _currentlyPlayingId == msg.id
                                      ? Icons.stop_circle
                                      : Icons.play_circle_fill,
                                  color: AppTheme.cyanAccent,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _currentlyPlayingId == msg.id
                                      ? 'Stop Voice'
                                      : 'Play Voice (${msg.language?.toUpperCase() ?? "EN"})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.cyanAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Embedded Resolution Card for Assistant responses with structured actions
          if (res != null && res.outcome != 'INFO_ONLY') ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: _buildResolutionCard(res),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResolutionCard(AgentResolution res) {
    Color badgeColor = AppTheme.tealPrimary;
    String badgeText = res.outcome;

    if (res.outcome == 'AUTO_RESOLVED') {
      badgeColor = AppTheme.emeraldSuccess;
      badgeText = 'AUTO RESOLVED (REFUND COMPLETE)';
    } else if (res.outcome == 'PENDING_APPROVAL') {
      badgeColor = AppTheme.amberWarning;
      badgeText = 'QUEUED FOR ADMIN APPROVAL';
    } else if (res.outcome == 'ESCALATED') {
      badgeColor = AppTheme.roseDanger;
      badgeText = res.ticket?.category == 'FRAUD_DISPUTE'
          ? 'ESCALATED TO FRAUD DESK'
          : 'ESCALATED TO SUPPORT';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
              if (res.confidence != null)
                Text(
                  'Confidence: ${(res.confidence! * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (res.refund != null) ...[
            Text(
              'Refund ID: ${res.refund!.refundId}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Amount: ₹${res.refund!.amount.toStringAsFixed(2)} • Status: ${res.refund!.status}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.emeraldSuccess,
              ),
            ),
          ],

          if (res.approval != null) ...[
            Text(
              'Approval ID: ${res.approval!.approvalId}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Amount: ₹${res.approval!.amount.toStringAsFixed(2)} (Awaiting Supervisor Sign-off)',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.amberWarning,
              ),
            ),
          ],

          if (res.ticket != null) ...[
            Text(
              'Dispute Ticket: ${res.ticket!.ticketId}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Category: ${res.ticket!.category} • Priority: ${res.ticket!.priority}',
              style: const TextStyle(fontSize: 12, color: AppTheme.roseDanger),
            ),
          ],

          const SizedBox(height: 10),
          Row(
            children: [
              if (res.paymentId != null)
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TransactionDetailsScreen(paymentId: res.paymentId!),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.receipt_long,
                    size: 14,
                    color: AppTheme.cyanAccent,
                  ),
                  label: const Text(
                    'View Payment',
                    style: TextStyle(fontSize: 11, color: AppTheme.cyanAccent),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
