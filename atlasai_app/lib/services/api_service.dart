import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/payment_model.dart';
import '../models/complaint_model.dart';
import '../models/agent_resolution_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Override for another device/network with --dart-define=API_BASE_URL=...
  String get baseUrl {
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredUrl.isNotEmpty) {
      return configuredUrl.replaceFirst(RegExp(r'/+$'), '');
    }
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.2.30.85:8000';
    }
    return 'http://localhost:8000';
  }

  /// Sends a complaint to the multi-agent orchestrator pipeline
  Future<AgentResolution> resolveComplaint({
    required String complaintText,
    String? paymentId,
    String? customerId = 'CUST101',
    String? language = 'en',
  }) async {
    final uri = Uri.parse('$baseUrl/api/agents/resolve');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'complaint_text': complaintText,
        'payment_id': paymentId,
        'customer_id': customerId,
        'language': language,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return AgentResolution.fromJson(data);
    } else {
      throw Exception(
        'Failed to resolve complaint: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Fetches recent payment records
  Future<List<PaymentItem>> fetchPayments({String? customerId}) async {
    var url = '$baseUrl/api/payments';
    if (customerId != null) url += '?customer_id=$customerId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => PaymentItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch payments: ${response.statusCode}');
    }
  }

  /// Fetches a single payment record by payment_id
  Future<PaymentItem> fetchPayment(String paymentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/payments/$paymentId'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return PaymentItem.fromJson(data);
    } else {
      throw Exception('Payment not found: $paymentId');
    }
  }

  /// Fetches all complaints
  Future<List<ComplaintItem>> fetchComplaints() async {
    final response = await http.get(Uri.parse('$baseUrl/api/complaints'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => ComplaintItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch complaints');
    }
  }

  /// Fetches a specific complaint by ID
  Future<ComplaintItem> fetchComplaint(String complaintId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/complaints/$complaintId'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return ComplaintItem.fromJson(data);
    } else {
      throw Exception('Complaint not found: $complaintId');
    }
  }

  /// Transcribes audio via Sarvam STT
  Future<Map<String, dynamic>> transcribeAudio({
    Uint8List? audioBytes,
    String? audioBase64,
    String? languageCode,
  }) async {
    final uri = Uri.parse('$baseUrl/api/voice/transcribe');
    final request = http.MultipartRequest('POST', uri);

    if (audioBytes != null && audioBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes('file', audioBytes, filename: 'audio.wav'),
      );
    } else if (audioBase64 != null) {
      request.fields['audio_base64'] = audioBase64;
    }
    if (languageCode != null) {
      request.fields['language_code'] = languageCode;
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Voice transcription failed');
    }
  }

  /// Synthesizes speech via Sarvam TTS
  Future<String> synthesizeSpeech(String text, String languageCode) async {
    final uri = Uri.parse('$baseUrl/api/voice/synthesize');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text, 'language_code': languageCode}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['audio_base64'] ?? '';
    }
    return '';
  }
}
