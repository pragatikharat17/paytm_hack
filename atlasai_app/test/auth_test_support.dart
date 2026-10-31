import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:atlasai_app/services/auth_service.dart';

class TestUser implements User {
  @override
  final String uid;
  TestUser(this.uid);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestAuthService extends AuthService {
  final controller = StreamController<User?>.broadcast();
  User? user;
  Object? failure;
  int logins = 0;
  int registrations = 0;
  int resets = 0;
  int signouts = 0;
  final refreshes = <bool>[];
  TestAuthService({this.user});
  @override
  Stream<User?> authStateChanges() async* {
    yield user;
    yield* controller.stream;
  }

  void emit(User? value) {
    user = value;
    controller.add(value);
  }

  @override
  Future<void> login(String email, String password) async {
    logins++;
    if (failure != null) throw failure!;
    emit(TestUser('test-user'));
  }

  @override
  Future<void> register(String email, String password) async {
    registrations++;
    if (failure != null) throw failure!;
    emit(TestUser('test-user'));
  }

  @override
  Future<void> resetPassword(String email) async {
    resets++;
    if (failure != null) throw failure!;
  }

  @override
  Future<void> signOut() async {
    signouts++;
    emit(null);
  }

  @override
  Future<String> idToken({bool forceRefresh = false}) async {
    refreshes.add(forceRefresh);
    return forceRefresh ? 'refreshed-token' : 'initial-token';
  }
}
