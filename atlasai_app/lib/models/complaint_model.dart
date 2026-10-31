class ComplaintItem {
  final int? id;
  final String complaintId;
  final String? customerId;
  final String? paymentId;
  final String rawText;
  final String originalLanguage;
  final String? intent;
  final String status;
  final String? resolutionSummary;
  final String? audioUrl;
  final DateTime? createdAt;

  ComplaintItem({
    this.id,
    required this.complaintId,
    this.customerId,
    this.paymentId,
    required this.rawText,
    this.originalLanguage = 'en',
    this.intent,
    required this.status,
    this.resolutionSummary,
    this.audioUrl,
    this.createdAt,
  });

  factory ComplaintItem.fromJson(Map<String, dynamic> json) {
    return ComplaintItem(
      id: json['id'],
      complaintId: json['complaint_id'] ?? '',
      customerId: json['customer_id'],
      paymentId: json['payment_id'],
      rawText: json['raw_text'] ?? '',
      originalLanguage: json['original_language'] ?? 'en',
      intent: json['intent'],
      status: json['status'] ?? 'NEW',
      resolutionSummary: json['resolution_summary'],
      audioUrl: json['audio_url'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}
