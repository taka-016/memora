import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/dtos/member/member_invitation_dto.dart';
import 'package:memora/application/queries/member/member_invitation_query_service.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';
import 'package:memora/domain/repositories/group/group_repository.dart';
import 'package:memora/domain/repositories/member/member_event_repository.dart';
import 'package:memora/domain/repositories/member/member_invitation_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/presentation/features/member/member_edit_modal.dart';
import 'package:memora/presentation/features/member/member_management.dart';
import 'package:memora/presentation/notifiers/current_member_notifier.dart';
import '../../../../helpers/test_exception.dart';

import '../../../../helpers/fake_current_member_notifier.dart';
import 'member_management_test.mocks.dart';

@GenerateMocks([
  MemberRepository,
  GroupRepository,
  MemberEventRepository,
  MemberInvitationRepository,
  MemberQueryService,
  MemberInvitationQueryService,
])
void main() {
  late MockMemberRepository mockMemberRepository;
  late MockGroupRepository mockGroupRepository;
  late MockMemberEventRepository mockMemberEventRepository;
  late MockMemberInvitationRepository mockMemberInvitationRepository;
  late MockMemberQueryService mockMemberQueryService;
  late MockMemberInvitationQueryService mockMemberInvitationQueryService;
  late MemberDto testMember;
  late List<Override> providerOverrides;

  setUp(() {
    mockMemberRepository = MockMemberRepository();
    mockGroupRepository = MockGroupRepository();
    mockMemberEventRepository = MockMemberEventRepository();
    mockMemberInvitationRepository = MockMemberInvitationRepository();
    mockMemberQueryService = MockMemberQueryService();
    mockMemberInvitationQueryService = MockMemberInvitationQueryService();
    testMember = MemberDto(
      id: 'test-member-id',
      accountId: 'test-account-id',
      ownerId: null,
      displayName: 'Test User',
      kanjiLastName: '山田',
      kanjiFirstName: '太郎',
      hiraganaLastName: 'やまだ',
      hiraganaFirstName: 'たろう',
      firstName: 'Taro',
      lastName: 'Yamada',
      gender: '男性',
      birthday: DateTime(1990, 1, 1),
      email: 'test@example.com',
      phoneNumber: '090-1234-5678',
      type: 'member',
    );

    // 共通的なモック設定: getMemberByIdはデフォルトでtestMemberを返す
    when(
      mockMemberQueryService.getMemberById(testMember.id),
    ).thenAnswer((_) async => testMember);

    providerOverrides = [
      memberRepositoryProvider.overrideWithValue(mockMemberRepository),
      groupRepositoryProvider.overrideWithValue(mockGroupRepository),
      memberEventRepositoryProvider.overrideWithValue(
        mockMemberEventRepository,
      ),
      memberInvitationRepositoryProvider.overrideWithValue(
        mockMemberInvitationRepository,
      ),
      memberQueryServiceProvider.overrideWithValue(mockMemberQueryService),
      memberInvitationQueryServiceProvider.overrideWithValue(
        mockMemberInvitationQueryService,
      ),
      currentMemberNotifierProvider.overrideWith(
        () => FakeCurrentMemberNotifier.loaded(testMember),
      ),
    ];
  });

  Widget createApp({Widget? home}) {
    final defaultHome = const Scaffold(body: MemberManagement());

    return ProviderScope(
      overrides: providerOverrides,
      child: MaterialApp(home: home ?? defaultHome),
    );
  }

  group('MemberManagement', () {
    testWidgets('管理しているメンバーがいない場合でもログインユーザーが表示されること', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createApp());

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('メンバー追加ボタンが表示されること', (WidgetTester tester) async {
      // Arrange
      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createApp());

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('メンバー追加'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('データ読み込みエラー時にスナックバーが表示されること', (WidgetTester tester) async {
      // Arrange
      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenThrow(TestException('Network error'));

      // Act
      await tester.pumpWidget(createApp());

      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('データの読み込みに失敗しました: TestException: Network error'),
        findsOneWidget,
      );
    });

    testWidgets('データ読み込みエラー時は追加を無効化し再試行を表示すること', (WidgetTester tester) async {
      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenThrow(TestException('Network error'));

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      final addButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'メンバー追加'),
      );
      expect(addButton.onPressed, isNull);
      expect(find.text('メンバー一覧を読み込めませんでした'), findsOneWidget);
      expect(find.text('再試行'), findsOneWidget);
    });

    testWidgets('メンバー追加ボタンタップで新規作成画面に遷移すること', (WidgetTester tester) async {
      // Arrange
      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createApp());

      await tester.pumpAndSettle();

      // タップ前は新規作成モーダルが表示されていないことを確認
      expect(find.text('メンバー新規作成'), findsNothing);

      // メンバー追加ボタンをタップ
      await tester.tap(find.text('メンバー追加'));
      await tester.pumpAndSettle();

      // 新規作成モーダルが開いていることを確認
      expect(find.text('メンバー新規作成'), findsOneWidget);
    });

    testWidgets('行タップで編集画面に遷移すること', (WidgetTester tester) async {
      // Arrange
      final managedMembers = [
        MemberDto(
          id: 'managed-member-1',
          accountId: null,
          ownerId: testMember.id,
          displayName: 'Managed User 1',
          kanjiLastName: '佐藤',
          kanjiFirstName: '花子',
          hiraganaLastName: 'さとう',
          hiraganaFirstName: 'はなこ',
          firstName: 'Hanako',
          lastName: 'Sato',
          gender: '女性',
          birthday: DateTime(1995, 5, 15),
          email: 'hanako@example.com',
          phoneNumber: '090-9876-5432',
          type: 'member',
        ),
      ];

      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => managedMembers);

      // Act
      await tester.pumpWidget(createApp());

      await tester.pumpAndSettle();

      // タップ前は編集モーダルが表示されていないことを確認
      expect(find.text('メンバー編集'), findsNothing);

      // 管理メンバーの行をタップ（2番目のListTile）
      await tester.tap(find.byType(ListTile).at(1));
      await tester.pump();

      // 編集モーダルが開いていることを確認
      expect(find.text('メンバー編集'), findsOneWidget);
    });

    testWidgets('メンバーの作成ができること', (WidgetTester tester) async {
      // Arrange
      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => []);

      when(mockMemberRepository.saveMember(any)).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createApp());

      await tester.pumpAndSettle();

      // メンバー追加ボタンをタップして新規作成モーダルを開く
      await tester.tap(find.text('メンバー追加'));
      await tester.pumpAndSettle();

      // 表示名を入力
      await tester.enterText(
        find.widgetWithText(TextFormField, '表示名'),
        'New Member',
      );

      // 作成ボタンをタップ
      await tester.tap(find.text('作成'));
      await tester.pumpAndSettle();

      // Assert - 作成処理が呼ばれることを確認
      verify(mockMemberRepository.saveMember(any)).called(1);
    });

    testWidgets('メンバー情報の更新ができること', (WidgetTester tester) async {
      // Arrange
      final managedMembers = [
        MemberDto(
          id: 'managed-member-1',
          accountId: null,
          ownerId: testMember.id,
          displayName: 'Managed User 1',
          kanjiLastName: '佐藤',
          kanjiFirstName: '花子',
          hiraganaLastName: 'さとう',
          hiraganaFirstName: 'はなこ',
          firstName: 'Hanako',
          lastName: 'Sato',
          gender: '女性',
          birthday: DateTime(1995, 5, 15),
          email: 'hanako@example.com',
          phoneNumber: '090-9876-5432',
          type: 'member',
        ),
      ];

      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => managedMembers);

      when(mockMemberRepository.updateMember(any)).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createApp());

      await tester.pumpAndSettle();

      // 管理メンバーの行をタップして編集モーダルを開く（2番目のListTile）
      await tester.tap(find.byType(ListTile).at(1));
      await tester.pumpAndSettle();

      // 表示名を変更
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Managed User 1'),
        'Updated Member Name',
      );

      // 更新ボタンをタップ
      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      // Assert - 更新処理が呼ばれることを確認
      verify(mockMemberRepository.updateMember(any)).called(1);
    });

    testWidgets('ログインユーザーメンバーの取得に失敗した場合、エラーが表示されること', (
      WidgetTester tester,
    ) async {
      AppLogger.suppressLogging(true);

      // Arrange
      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => []);

      when(
        mockMemberQueryService.getMemberById(testMember.id),
      ).thenAnswer((_) async => null); // nullを返すように設定

      // Act
      await tester.pumpWidget(createApp());

      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('データの読み込みに失敗しました: Exception: ログインユーザーメンバーの最新情報の取得に失敗しました'),
        findsOneWidget,
      );
    });

    testWidgets('accountIdを持つメンバーは削除ボタンが表示されないこと', (WidgetTester tester) async {
      // Arrange
      final managedMembers = [
        // accountIdを持つメンバー（削除ボタンが表示されない）
        MemberDto(
          id: 'managed-member-1',
          accountId: 'account-id-1',
          ownerId: testMember.id,
          displayName: 'Account Linked Member',
        ),
        // accountIdを持たないメンバー（削除ボタンが表示される）
        MemberDto(
          id: 'managed-member-2',
          accountId: null,
          ownerId: testMember.id,
          displayName: 'Regular Member',
        ),
      ];

      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => managedMembers);

      // Act
      await tester.pumpWidget(createApp());

      await tester.pumpAndSettle();

      // Assert
      final cards = find.byType(Card);
      expect(cards, findsNWidgets(3)); // ログインユーザー + 管理メンバー2人

      // 1行目（ログインユーザー）- accountIdありなので削除ボタンなし
      final firstCard = cards.at(0);
      expect(
        find.descendant(of: firstCard, matching: find.byIcon(Icons.delete)),
        findsNothing,
      );

      // 2行目（accountIdありのメンバー）- 削除ボタンなし
      final secondCard = cards.at(1);
      expect(
        find.descendant(
          of: secondCard,
          matching: find.text('Account Linked Member'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: secondCard, matching: find.byIcon(Icons.delete)),
        findsNothing,
      );

      // 3行目（accountIdなしのメンバー）- 削除ボタンあり
      final thirdCard = cards.at(2);
      expect(
        find.descendant(of: thirdCard, matching: find.text('Regular Member')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: thirdCard, matching: find.byIcon(Icons.delete)),
        findsOneWidget,
      );
    });

    testWidgets('既存メンバーの編集画面に招待ボタンが表示されること', (WidgetTester tester) async {
      // Arrange
      final managedMembers = [
        MemberDto(
          id: 'managed-member-1',
          accountId: null,
          ownerId: testMember.id,
          displayName: 'Managed User 1',
        ),
      ];

      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => managedMembers);

      // Act
      await tester.pumpWidget(createApp());

      await tester.pumpAndSettle();

      // 管理メンバーの行をタップして編集モーダルを開く
      await tester.tap(find.byType(ListTile).at(1));
      await tester.pumpAndSettle();

      // Assert - 編集画面に招待ボタンが表示されること
      expect(find.text('招待'), findsOneWidget);
      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('招待ボタンクリック時に招待コードが生成されダイアログが表示されること', (
      WidgetTester tester,
    ) async {
      // Arrange
      final managedMembers = [
        MemberDto(
          id: 'managed-member-1',
          accountId: null,
          ownerId: testMember.id,
          displayName: 'Managed User 1',
        ),
      ];

      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => managedMembers);

      when(
        mockMemberInvitationQueryService.getByInviteeId('managed-member-1'),
      ).thenAnswer((_) async => null);

      when(
        mockMemberInvitationRepository.saveMemberInvitation(any),
      ).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createApp());

      await tester.pumpAndSettle();

      // 管理メンバーの行をタップして編集モーダルを開く
      await tester.tap(find.byType(ListTile).at(1));
      await tester.pumpAndSettle();

      // 招待ボタンをタップ
      await tester.tap(find.text('招待'));
      await tester.pumpAndSettle();

      // Assert - 招待コード表示ダイアログが開いていること
      expect(find.text('招待コード'), findsOneWidget);
      expect(find.text('Managed User 1さんの招待コードが生成されました。'), findsOneWidget);
      expect(find.text('共有'), findsOneWidget);
      expect(find.text('閉じる'), findsOneWidget);

      // 招待の保存処理が呼ばれることを確認
      verify(
        mockMemberInvitationRepository.saveMemberInvitation(any),
      ).called(1);
    });

    testWidgets('招待コードの生成失敗時にスナックバーが表示されること', (WidgetTester tester) async {
      final managedMembers = [
        MemberDto(
          id: 'managed-member-1',
          accountId: null,
          ownerId: testMember.id,
          displayName: 'Managed User 1',
        ),
      ];
      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => managedMembers);
      when(
        mockMemberInvitationQueryService.getByInviteeId('managed-member-1'),
      ).thenThrow(TestException('招待生成失敗'));

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ListTile).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('招待'));
      await tester.pumpAndSettle();

      expect(
        find.text('招待コードの生成に失敗しました: TestException: 招待生成失敗'),
        findsOneWidget,
      );
      expect(find.text('招待コード'), findsNothing);
    });

    testWidgets('招待生成中に編集画面を閉じた場合は招待コード画面を開かないこと', (WidgetTester tester) async {
      final managedMembers = [
        MemberDto(
          id: 'managed-member-1',
          accountId: null,
          ownerId: testMember.id,
          displayName: 'Managed User 1',
        ),
      ];
      final invitationCompleter = Completer<MemberInvitationDto?>();
      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => managedMembers);
      when(
        mockMemberInvitationQueryService.getByInviteeId('managed-member-1'),
      ).thenAnswer((_) => invitationCompleter.future);
      when(
        mockMemberInvitationRepository.saveMemberInvitation(any),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ListTile).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('招待'));
      await tester.pump();

      final editContext = tester.element(find.byType(MemberEditModal));
      Navigator.of(editContext).pop();
      await tester.pumpAndSettle();
      invitationCompleter.complete(null);
      await tester.pumpAndSettle();

      expect(find.text('招待コード'), findsNothing);
    });

    testWidgets('ログインユーザーの編集画面には招待ボタンが表示されないこと', (WidgetTester tester) async {
      // Arrange
      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createApp());

      await tester.pumpAndSettle();

      // ログインユーザーの行をタップして編集モーダルを開く
      await tester.tap(find.byType(ListTile).at(0));
      await tester.pumpAndSettle();

      // Assert - ログインユーザーの編集画面には招待ボタンが表示されないこと
      expect(find.text('招待'), findsNothing);
      expect(find.byIcon(Icons.person_add), findsNothing);
    });
  });
}
