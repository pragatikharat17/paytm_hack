import 'agent_resolution_model.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final AgentResolution? resolution;
  final bool isThinking;
  final String? audioBase64;
  final String? language;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.resolution,
    this.isThinking = false,
    this.audioBase64,
    this.language,
  });
}