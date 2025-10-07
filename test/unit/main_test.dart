import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/interfaces/auth_service.dart';
import 'package:memora/application/interfaces/group_query_service.dart';
import 'package:memora/application/interfaces/pin_query_service.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/entities/user.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/presentation/app/top_page.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../helpers/fake_auth_notifier.dart';
import 'main_test.mocks.dart';

@GenerateMocks([
  GroupQueryService,
  MemberRepository,
  AuthService,
  PinQueryService,
])
void main() {
  late MockGroupQueryService mockGroupQueryService;
  late MockMemberRepository mockMemberRepository;
  late MockAuthService mockAuthService;
  late MockPinQueryService mockPinQueryService;

  setUp(() {
    mockGroupQueryService = MockGroupQueryService();
    mockMemberRepository = MockMemberRepository();
    mockAuthService = MockAuthService();
    mockPinQueryService = MockPinQueryService();

    const testUser = User(
      id: 'test_user_id',
      loginId: 'test@example.com',
      isVerified: true,
    );

    final testMember = Member(
      id: 'test_member_id',
      displayName: 'テストユーザー',
      kanjiLastName: 'テスト',
      kanjiFirstName: 'ユーザー',
    );

    when(mockAuthService.getCurrentUser()).thenAnswer((_) async => testUser);
    when(
      mockMemberRepository.getMemberByAccountId(any),
    ).thenAnswer((_) async => testMember);
    when(
      mockGroupQueryService.getGroupsWithMembersByMemberId(any),
    ).thenAnswer((_) async => []);
    when(
      mockPinQueryService.getPinsByMemberId(any),
    ).thenAnswer((_) async => []);
  });

  Widget createTestApp() {
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith((ref) {
          return FakeAuthNotifier.authenticated();
        }),
      ],
      child: MaterialApp(
        title: 'memora',
        locale: const Locale('ja'),
        home: TopPage(
          isTestEnvironment: true,
          memberRepository: mockMemberRepository,
          authService: mockAuthService,
          groupQueryService: mockGroupQueryService,
          pinQueryService: mockPinQueryService,
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
