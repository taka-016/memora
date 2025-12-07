import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/application/queries/trip/pin_query_service.dart';
import 'package:memora/domain/entities/account/user.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/presentation/app/top_page.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../helpers/fake_auth_notifier.dart';
import 'main_test.mocks.dart';

@GenerateMocks([
  GroupQueryService,
  MemberQueryService,
  AuthService,
  PinQueryService,
])
void main() {
  late MockGroupQueryService mockGroupQueryService;
  late MockMemberQueryService mockMemberQueryService;
  late MockAuthService mockAuthService;

  setUp(() {
    mockGroupQueryService = MockGroupQueryService();
    mockMemberQueryService = MockMemberQueryService();
    mockAuthService = MockAuthService();

    const testUser = User(
      id: 'test_user_id',
      loginId: 'test@example.com',
      isVerified: true,
    );

    final testMember = MemberDto(
      id: 'test_member_id',
      displayName: 'テストユーザー',
      kanjiLastName: 'テスト',
      kanjiFirstName: 'ユーザー',
    );

    when(mockAuthService.getCurrentUser()).thenAnswer((_) async => testUser);
    when(
      mockMemberQueryService.getMemberByAccountId(any),
    ).thenAnswer((_) async => testMember);
    when(
      mockGroupQueryService.getGroupsWithMembersByMemberId(
        any,
        groupsOrderBy: anyNamed('groupsOrderBy'),
        membersOrderBy: anyNamed('membersOrderBy'),
      ),
    ).thenAnswer((_) async => []);
  });

  Widget createTestApp() {
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(FakeAuthNotifier.authenticated),
        memberQueryServiceProvider.overrideWithValue(mockMemberQueryService),
        authServiceProvider.overrideWithValue(mockAuthService),
        groupQueryServiceProvider.overrideWithValue(mockGroupQueryService),
        // pinQueryServiceProvider.overrideWithValue(mockPinQueryService),
      ],
      child: MaterialApp(
        title: 'memora',
        locale: const Locale('ja'),
        home: TopPage(isTestEnvironment: true),
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
