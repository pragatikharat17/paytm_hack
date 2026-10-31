import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/payment_model.dart';
import '../models/complaint_model.dart';
import '../models/agent_resolution_model.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  final AuthService _auth;
  ApiService._internal() : _auth = AuthService.instance;
  @visibleForTesting
  ApiService.withAuth(this._auth);

  /// Firebase refreshes normally expired tokens. Retry one rejected token, then
  /// sign out so AuthGate removes all private routes.
  Future<http.Response> _authorized(
    Future<http.Response> Function(Map<String, String>) send,
  ) async {
    try {
      for (var attempt = 0; attempt < 2; attempt++) {
        final token = await _auth.idToken(forceRefresh: attempt > 0);
        final response = await send({
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        });
        if (response.statusCode != 401) return response;
      }
      await _auth.signOut();
      throw FirebaseAuthException(code: 'requires-recent-login');
    } on FirebaseAuthException catch (error) {
      if ([
        'user-token-expired',
        'invalid-user-token',
        'user-disabled',
        'user-not-found',
      ].contains(error.code)) {
        await _auth.signOut();
      }
      rethrow;
    }
  }

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
    String? customerId,
    String? language = 'en',
  }) async {
    final uri = Uri.parse('$baseUrl/api/agents/resolve');
    final response = await _authorized(
      (headers) => http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'complaint_text': complaintText,
          'payment_id': paymentId,
          'customer_id': customerId,
          'language': language,
        }),
      ),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return AgentResolution.fromJson(data);
    } else {
      throw _resolutionError(response);
    }
  }

  ApiException _resolutionError(http.Response response) {
    switch (response.statusCode) {
      case 401:
        return const ApiException(
          401,
          'Your session has expired. Please sign in again.',
        );
      case 403:
        return const ApiException(
          403,
          'You do not have access to this payment.',
        );
      case 404:
        return const ApiException(
          404,
          'This payment is not linked to your account. Use a payment from your history, or ask the AtlasAI administrator to link the demo account.',
        );
      case 503:
        return const ApiException(
          503,
          'The secure resolution service is temporarily unavailable. Please try again shortly.',
        );
      default:
        return const ApiException(
          0,
          'We could not process this request. Please try again.',
        );
    }
  }

  /// Fetches recent payment records
  Future<List<PaymentItem>> fetchPayments({String? customerId}) async {
    var url = '$baseUrl/api/payments';
    if (customerId != null) url += '?customer_id=$customerId';
    final response = await _authorized(
      (headers) => http.get(Uri.parse(url), headers: headers),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => PaymentItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch payments: ${response.statusCode}');
    }
  }

  /// Fetches a single payment record by payment_id
  Future<PaymentItem> fetchPayment(String paymentId) async {
    final response = await _authorized(
      (headers) => http.get(
        Uri.parse('$baseUrl/api/payments/$paymentId'),
        headers: headers,
      ),
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
    final response = await _authorized(
      (headers) =>
          http.get(Uri.parse('$baseUrl/api/complaints'), headers: headers),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => ComplaintItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch complaints');
    }
  }

  /// Fetches a specific complaint by ID
  Future<ComplaintItem> fetchComplaint(String complaintId) async {
    final response = await _authorized(
      (headers) => http.get(
        Uri.parse('$baseUrl/api/complaints/$complaintId'),
        headers: headers,
      ),
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
    final response = await _authorized((headers) async {
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = headers['Authorization']!;

      if (audioBytes != null && audioBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            audioBytes,
            filename: 'audio.wav',
          ),
        );
      } else if (audioBase64 != null) {
        request.fields['audio_base64'] = audioBase64;
      }
      if (languageCode != null) {
        request.fields['language_code'] = languageCode;
      }

      final streamedResponse = await request.send();
      return http.Response.fromStream(streamedResponse);
    });

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Voice transcription failed');
    }
  }

  /// Synthesizes speech via Sarvam TTS
  Future<String> synthesizeSpeech(String text, String languageCode) async {
    final uri = Uri.parse('$baseUrl/api/voice/synthesize');
    final response = await _authorized(
      (headers) => http.post(
        uri,
        headers: headers,
        body: jsonEncode({'text': text, 'language_code': languageCode}),
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['audio_base64'] ?? '';
    }
    return '';
  }
}
