import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/interfaces/auth_service.dart';
import 'package:memora/domain/entities/user.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/presentation/features/account_setting/account_settings.dart';

class _FakeAuthService implements AuthService {
  @override
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Stream<User?> get authStateChanges => Stream<User?>.empty();

  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Future<void> deleteUser() async {}

  @override
  Future<void> reauthenticate({required String password}) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updateEmail({required String newEmail}) async {}

  @override
  Future<void> updatePassword({required String newPassword}) async {}

  @override
  Future<void> validateCurrentUserToken() async {}
}

Widget _buildTestApp(Widget child) {
  return ProviderScope(
    overrides: [authServiceProvider.overrideWithValue(_FakeAuthService())],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('AccountSettings', () {
    testWidgets('アカウント設定画面が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp(const AccountSettings()));

      expect(find.text('アカウント設定'), findsOneWidget);
    });

    testWidgets('メールアドレス変更セクションが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp(const AccountSettings()));

      expect(find.text('メールアドレス変更'), findsOneWidget);
    });

    testWidgets('パスワード変更セクションが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp(const AccountSettings()));

      expect(find.text('パスワード変更'), findsOneWidget);
    });

    testWidgets('アカウント削除セクションが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp(const AccountSettings()));

      expect(find.text('アカウント削除'), findsOneWidget);
    });
  });
}
