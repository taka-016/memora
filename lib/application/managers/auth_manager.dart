import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/entities/user.dart';
import '../../domain/services/auth_service.dart';

class AuthManager extends ChangeNotifier {
  AuthManager({required this.authService}) : _state = const AuthState.loading();

  final AuthService authService;
  AuthState _state;
  StreamSubscription<User?>? _authStateSubscription;

  AuthState get state => _state;

  Future<void> initialize() async {
    try {
      final currentUser = await authService.getCurrentUser();
      if (currentUser != null) {
        _updateState(AuthState.authenticated(currentUser));
      } else {
        _updateState(const AuthState.unauthenticated());
      }

      _authStateSubscription = authService.authStateChanges.listen((user) {
        if (user != null) {
          _updateState(AuthState.authenticated(user));
        } else {
          _updateState(const AuthState.unauthenticated());
        }
      });
    } catch (e) {
      _updateState(AuthState.error('初期化に失敗しました: ${e.toString()}'));
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      _updateState(const AuthState.loading());
      final user = await authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _updateState(AuthState.authenticated(user));
    } catch (e) {
      _updateState(AuthState.error('ログインに失敗しました: ${e.toString()}'));
    }
  }

  Future<void> signup({
    required String email,
    required String password,
  }) async {
    try {
      _updateState(const AuthState.loading());
      final user = await authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _updateState(AuthState.authenticated(user));
    } catch (e) {
      _updateState(AuthState.error('サインアップに失敗しました: ${e.toString()}'));
    }
  }

  Future<void> logout() async {
    try {
      _updateState(const AuthState.loading());
      await authService.signOut();
      _updateState(const AuthState.unauthenticated());
    } catch (e) {
      _updateState(AuthState.error('ログアウトに失敗しました: ${e.toString()}'));
    }
  }

  Future<void> sendPasswordlessSignInLink({
    required String email,
  }) async {
    try {
      await authService.sendSignInLinkToEmail(email: email);
    } catch (e) {
      _updateState(AuthState.error('メール送信に失敗しました: ${e.toString()}'));
    }
  }

  Future<void> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    try {
      _updateState(const AuthState.loading());
      final user = await authService.signInWithEmailLink(
        email: email,
        emailLink: emailLink,
      );
      _updateState(AuthState.authenticated(user));
    } catch (e) {
      _updateState(AuthState.error('サインインに失敗しました: ${e.toString()}'));
    }
  }

  void clearError() {
    if (_state.status == AuthStatus.error) {
      _updateState(const AuthState.unauthenticated());
    }
  }

  void _updateState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}