import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/get_current_member_usecase.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/presentation/widgets/user_drawer_header.dart';

import 'user_drawer_header_test.mocks.dart';

@GenerateMocks([GetCurrentMemberUseCase])
void main() {
  late MockGetCurrentMemberUseCase mockGetCurrentMemberUseCase;

  setUp(() {
    mockGetCurrentMemberUseCase = MockGetCurrentMemberUseCase();
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: UserDrawerHeader(
          getCurrentMemberUseCase: mockGetCurrentMemberUseCase,
        ),
      ),
    );
  }

  group('UserDrawerHeader', () {
    testWidgets('ニックネームが設定されている場合、ニックネームが表示される', (WidgetTester tester) async {
      // Arrange
      final member = Member(
        id: 'member123',
        nickname: 'テストユーザー',
        kanjiLastName: '田中',
        kanjiFirstName: '太郎',
      );
      when(
        mockGetCurrentMemberUseCase.execute(),
      ).thenAnswer((_) async => member);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('memora'), findsOneWidget);
      expect(find.text('テストユーザー'), findsOneWidget);
      expect(find.text('田中 太郎'), findsNothing);
    });

    testWidgets('ニックネームが未設定で漢字姓名が設定されている場合、漢字姓名が表示される', (
      WidgetTester tester,
    ) async {
      // Arrange
      final member = Member(
        id: 'member123',
        kanjiLastName: '田中',
        kanjiFirstName: '太郎',
      );
      when(
        mockGetCurrentMemberUseCase.execute(),
      ).thenAnswer((_) async => member);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('memora'), findsOneWidget);
      expect(find.text('田中 太郎'), findsOneWidget);
    });

    testWidgets('kanjiLastNameとkanjiFirstNameが両方未設定の場合、名前未設定が表示される', (
      WidgetTester tester,
    ) async {
      // Arrange
      final member = Member(id: 'member123');
      when(
        mockGetCurrentMemberUseCase.execute(),
      ).thenAnswer((_) async => member);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('memora'), findsOneWidget);
      expect(find.text('名前未設定'), findsOneWidget);
    });

    testWidgets('メンバー情報が取得できない場合、名前未設定が表示される', (WidgetTester tester) async {
      // Arrange
      when(mockGetCurrentMemberUseCase.execute()).thenAnswer((_) async => null);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('memora'), findsOneWidget);
      expect(find.text('名前未設定'), findsOneWidget);
    });

    testWidgets('読み込み中は「読み込み中...」が表示される', (WidgetTester tester) async {
      // Arrange
      final completer = Completer<Member>();
      when(
        mockGetCurrentMemberUseCase.execute(),
      ).thenAnswer((_) => completer.future);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // 初回描画

      // Assert - 読み込み中状態を確認
      expect(find.text('memora'), findsOneWidget);
      expect(find.text('読み込み中...'), findsOneWidget);
      expect(find.text('テストユーザー'), findsNothing);

      // 読み込み完了をシミュレート
      completer.complete(Member(id: 'member123', nickname: 'テストユーザー'));
      await tester.pumpAndSettle(); // 全ての非同期処理完了まで待機

      // Assert - 読み込み完了後
      expect(find.text('テストユーザー'), findsOneWidget);
      expect(find.text('読み込み中...'), findsNothing);
    });

    testWidgets('エラーが発生した場合、名前未設定が表示される', (WidgetTester tester) async {
      // Arrange
      when(
        mockGetCurrentMemberUseCase.execute(),
      ).thenThrow(Exception('テストエラー'));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('memora'), findsOneWidget);
      expect(find.text('名前未設定'), findsOneWidget);
    });
  });
}
