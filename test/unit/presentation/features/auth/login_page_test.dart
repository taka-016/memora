import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/presentation/notifiers/auth/auth_state.dart';
import 'package:memora/presentation/notifiers/auth/auth_notifier.dart';
import 'package:memora/presentation/features/auth/login_page.dart';

import '../../../../helpers/fake_auth_notifier.dart';

void main() {
  group('LoginPage', () {
    testWidgets('ログインボタンをタップするとloginメソッドが呼ばれる', (WidgetTester tester) async {
      final fakeAuthNotifier = FakeAuthNotifier(
        const AuthState.unauthenticated(''),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => fakeAuthNotifier),
          ],
          child: const MaterialApp(home: LoginPage()),
        ),
      );

      final loginButton = find.byKey(const Key('login_button'));

      await tester.tap(loginButton);
      await tester.pump();

      expect(fakeAuthNotifier.loginCalled, isTrue);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('新規登録'), findsNothing);
    });
  });
}
