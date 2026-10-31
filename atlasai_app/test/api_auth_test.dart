import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:atlasai_app/services/api_service.dart';
import 'auth_test_support.dart';

void main() {
  test('API attaches token and retries an expired token once', () async {
    final auth = TestAuthService();
    final api = ApiService.withAuth(auth);
    var calls = 0;
    await http.runWithClient(
      () async {
        expect(await api.fetchPayments(), isEmpty);
      },
      () => MockClient((request) async {
        calls++;
        expect(
          request.headers['Authorization'],
          calls == 1 ? 'Bearer initial-token' : 'Bearer refreshed-token',
        );
        return http.Response(calls == 1 ? '' : '[]', calls == 1 ? 401 : 200);
      }),
    );
    expect(auth.refreshes, [false, true]);
    expect(auth.signouts, 0);
    await auth.controller.close();
  });
  test('Repeated 401 signs out; 403 does not sign out', () async {
    final auth = TestAuthService();
    final api = ApiService.withAuth(auth);
    await http.runWithClient(() async {
      await expectLater(
        api.fetchPayments(),
        throwsA(isA<FirebaseAuthException>()),
      );
    }, () => MockClient((_) async => http.Response('', 401)));
    expect(auth.signouts, 1);
    await http.runWithClient(() async {
      await expectLater(api.fetchPayments(), throwsException);
    }, () => MockClient((_) async => http.Response('', 403)));
    expect(auth.signouts, 1);
    await auth.controller.close();
  });
  test('Multipart voice requests carry authentication', () async {
    final auth = TestAuthService();
    await http.runWithClient(
      () async {
        await ApiService.withAuth(auth).transcribeAudio(audioBase64: 'YQ==');
      },
      () => MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer initial-token');
        expect(
          request.headers['content-type'],
          startsWith('multipart/form-data'),
        );
        return http.Response('{"transcript":"test"}', 200);
      }),
    );
    await auth.controller.close();
  });

  test('Resolution errors do not expose backend response details', () async {
    final auth = TestAuthService();
    await http.runWithClient(
      () async {
        await expectLater(
          ApiService.withAuth(
            auth,
          ).resolveComplaint(complaintText: 'Refund PAY1001'),
          throwsA(
            isA<ApiException>()
                .having((error) => error.statusCode, 'status code', 404)
                .having(
                  (error) => error.message,
                  'message',
                  contains('not linked to your account'),
                ),
          ),
        );
      },
      () => MockClient(
        (_) async => http.Response('{"detail":"Payment not found"}', 404),
      ),
    );
    await auth.controller.close();
  });
}
