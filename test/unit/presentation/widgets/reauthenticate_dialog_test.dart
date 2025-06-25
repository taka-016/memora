import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/presentation/widgets/reauthenticate_dialog.dart';
import 'package:memora/application/usecases/reauthenticate_usecase.dart';

import 'reauthenticate_dialog_test.mocks.dart';

@GenerateMocks([ReauthenticateUseCase])
void main() {
  group('ReauthenticateDialog', () {
    late MockReauthenticateUseCase mockReauthenticateUseCase;

    setUp(() {
      mockReauthenticateUseCase = MockReauthenticateUseCase();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ReauthenticateDialog(
                    reauthenticateUseCase: mockReauthenticateUseCase,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );
    }

    testWidgets('再認証ダイアログの基本要素が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('パスワード再入力'), findsOneWidget);
      expect(find.text('操作を続行するには、現在のパスワードを入力してください'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('認証'), findsOneWidget);
    });

    testWidgets('パスワードを入力できる', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextField);
      await tester.enterText(passwordField, 'CurrentPassword123!');

      expect(find.text('CurrentPassword123!'), findsOneWidget);
    });

    testWidgets('認証ボタンをタップすると再認証が実行される', (WidgetTester tester) async {
      when(
        mockReauthenticateUseCase.execute(password: anyNamed('password')),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextField);
      await tester.enterText(passwordField, 'CurrentPassword123!');
      await tester.tap(find.text('認証'));
      await tester.pump();

      verify(
        mockReauthenticateUseCase.execute(password: 'CurrentPassword123!'),
      ).called(1);
    });

    testWidgets('キャンセルボタンをタップするとダイアログが閉じる', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.byType(ReauthenticateDialog), findsNothing);
    });

    testWidgets('空のパスワードで認証ボタンをタップしてもダイアログは閉じない', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('認証'));
      await tester.pump();

      expect(find.byType(ReauthenticateDialog), findsOneWidget);
      verifyNever(
        mockReauthenticateUseCase.execute(password: anyNamed('password')),
      );
    });

    testWidgets('再認証エラー時にエラーメッセージが表示される', (WidgetTester tester) async {
      when(
        mockReauthenticateUseCase.execute(password: anyNamed('password')),
      ).thenThrow(Exception('認証に失敗しました'));

      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextField);
      await tester.enterText(passwordField, 'WrongPassword');
      await tester.tap(find.text('認証'));
      await tester.pump();

      expect(find.text('認証に失敗しました'), findsOneWidget);
    });
  });
}
