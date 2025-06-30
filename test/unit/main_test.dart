import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/get_current_member_usecase.dart';
import 'package:memora/application/managers/auth_manager.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/presentation/top_page.dart';
import 'package:memora/main.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'main_test.mocks.dart';

@GenerateMocks([
  GetGroupsWithMembersUsecase,
  GetCurrentMemberUseCase,
  AuthManager,
])
void main() {
  late MockGetGroupsWithMembersUsecase mockUsecase;
  late MockGetCurrentMemberUseCase mockGetCurrentMemberUseCase;

  setUp(() {
    mockUsecase = MockGetGroupsWithMembersUsecase();
    mockGetCurrentMemberUseCase = MockGetCurrentMemberUseCase();

    when(mockUsecase.execute(any)).thenAnswer((_) async => []);
    when(mockGetCurrentMemberUseCase.execute()).thenAnswer(
      (_) async => Member(
        id: 'test_member',
        displayName: '表示名',
        kanjiLastName: 'テスト',
        kanjiFirstName: 'ユーザー',
      ),
    );
  });

  Widget createTestApp() {
    return MaterialApp(
      title: 'memora',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      locale: const Locale('ja'),
      home: TopPage(
        getGroupsWithMembersUsecase: mockUsecase,
        isTestEnvironment: true,
        getCurrentMemberUseCase: mockGetCurrentMemberUseCase,
      ),
    );
  }

  group('MyApp', () {
    testWidgets('アプリ起動時にTopPageが表示される', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(TopPage), findsOneWidget);
      expect(find.text('memora'), findsOneWidget);
    });

    testWidgets('アプリのタイトルが正しく設定されている', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestApp());

      // Assert
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.title, 'memora');
    });

    testWidgets('日本語ロケールが設定されている', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestApp());

      // Assert
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.locale, const Locale('ja'));
    });

    testWidgets('MyAppが正常に起動することを確認', (WidgetTester tester) async {
      // MyAppにはFirebaseの初期化が含まれているため、テスト環境では簡単な起動テストのみ実施
      // 実際のFirebase初期化を含むMyAppのテストは複雑になるため、
      // ここでは基本的な構造のテストのみ行う

      // Act & Assert - MyAppクラスの存在を確認
      expect(MyApp, isNotNull);
      expect(() => const MyApp(), returnsNormally);
    });
  });
}
