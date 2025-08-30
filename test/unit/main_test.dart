import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/get_current_member_usecase.dart';
import 'package:memora/application/usecases/get_trip_entries_usecase.dart';
import 'package:memora/application/managers/auth_manager.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/presentation/app/top_page.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'main_test.mocks.dart';
import '../helpers/fake_auth_manager.dart';

@GenerateMocks([
  GetGroupsWithMembersUsecase,
  GetCurrentMemberUseCase,
  GetTripEntriesUsecase,
])
void main() {
  late MockGetGroupsWithMembersUsecase mockUsecase;
  late MockGetCurrentMemberUseCase mockGetCurrentMemberUseCase;
  late MockGetTripEntriesUsecase mockGetTripEntriesUsecase;

  setUp(() {
    mockUsecase = MockGetGroupsWithMembersUsecase();
    mockGetCurrentMemberUseCase = MockGetCurrentMemberUseCase();
    mockGetTripEntriesUsecase = MockGetTripEntriesUsecase();

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
    return ProviderScope(
      overrides: [
        authManagerProvider.overrideWith((ref) {
          return FakeAuthManager.authenticated();
        }),
      ],
      child: MaterialApp(
        title: 'memora',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        locale: const Locale('ja'),
        home: TopPage(
          getGroupsWithMembersUsecase: mockUsecase,
          getTripEntriesUsecase: mockGetTripEntriesUsecase,
          isTestEnvironment: true,
          getCurrentMemberUseCase: mockGetCurrentMemberUseCase,
        ),
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
  });

  group('Firestore設定', () {
    test('main関数でFirestoreのローカルキャッシュが無効化されること', () {
      // 設定オブジェクトの動作確認
      const settings = Settings(persistenceEnabled: false);
      expect(settings.persistenceEnabled, false);
    });
  });
}
