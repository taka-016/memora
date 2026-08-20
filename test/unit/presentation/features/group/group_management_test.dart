import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/domain/repositories/group/group_event_repository.dart';
import 'package:memora/domain/repositories/group/group_repository.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/presentation/features/group/group_management.dart';
import 'package:memora/presentation/notifiers/current_member_notifier.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import '../../../../helpers/test_exception.dart';

import '../../../../helpers/fake_current_member_notifier.dart';
import 'group_management_test.mocks.dart';

@GenerateMocks([
  GroupRepository,
  GroupEventRepository,
  GroupQueryService,
  MemberQueryService,
  TripEntryRepository,
])
void main() {
  late MockGroupRepository mockGroupRepository;
  late MockGroupEventRepository mockGroupEventRepository;
  late MockGroupQueryService mockGroupQueryService;
  late MockMemberQueryService mockMemberQueryService;
  late MockTripEntryRepository mockTripEntryRepository;
  late MemberDto testMember;
  late GroupDto groupWithMembers1;
  late GroupDto groupWithMembers2;
  late List<Override> providerOverrides;

  setUp(() {
    mockGroupRepository = MockGroupRepository();
    mockGroupEventRepository = MockGroupEventRepository();
    mockGroupQueryService = MockGroupQueryService();
    mockMemberQueryService = MockMemberQueryService();
    mockTripEntryRepository = MockTripEntryRepository();
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
    groupWithMembers1 = GroupDto(
      id: 'group-1',
      ownerId: testMember.id,
      name: 'Test Group 1',
      members: [],
    );
    groupWithMembers2 = GroupDto(
      id: 'group-2',
      ownerId: testMember.id,
      name: 'Test Group 2',
      members: [],
    );

    providerOverrides = [
      groupRepositoryProvider.overrideWithValue(mockGroupRepository),
      groupEventRepositoryProvider.overrideWithValue(mockGroupEventRepository),
      groupQueryServiceProvider.overrideWithValue(mockGroupQueryService),
      memberQueryServiceProvider.overrideWithValue(mockMemberQueryService),
      tripEntryRepositoryProvider.overrideWithValue(mockTripEntryRepository),
      currentMemberNotifierProvider.overrideWith(
        () => FakeCurrentMemberNotifier.loaded(testMember),
      ),
    ];
  });

  Widget createGroupManagementApp() {
    return ProviderScope(
      overrides: providerOverrides,
      child: MaterialApp(home: const Scaffold(body: GroupManagement())),
    );
  }

  group('GroupManagement', () {
    testWidgets('初期化時にグループリストが読み込まれること', (WidgetTester tester) async {
      // Arrange
      final managedGroupsWithMembers = [groupWithMembers1, groupWithMembers2];

      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => managedGroupsWithMembers);

      // Act
      await tester.pumpWidget(createGroupManagementApp());

      // 初期ローディング状態を確認
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // ローディング完了まで待機
      await tester.pumpAndSettle();

      // Assert
      verify(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).called(1);
      expect(find.text('グループ管理'), findsOneWidget);
      expect(find.text('Test Group 1'), findsOneWidget);
      expect(find.text('Test Group 2'), findsOneWidget);
    });

    testWidgets('管理しているグループがない場合、空状態が表示されること', (WidgetTester tester) async {
      // Arrange
      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createGroupManagementApp());

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ListTile), findsNothing);
      expect(find.text('管理しているグループがありません'), findsOneWidget);
      expect(find.text('グループを追加してください'), findsOneWidget);
    });

    testWidgets('グループ追加ボタンが表示されること', (WidgetTester tester) async {
      // Arrange
      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createGroupManagementApp());

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('グループ追加'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('データ読み込みエラー時にスナックバーが表示されること', (WidgetTester tester) async {
      // Arrange
      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenThrow(TestException('Network error'));

      // Act
      await tester.pumpWidget(createGroupManagementApp());

      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('データの読み込みに失敗しました: TestException: Network error'),
        findsOneWidget,
      );
    });

    testWidgets('データ読み込みエラー時はグループ追加を開始しないこと', (WidgetTester tester) async {
      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenThrow(TestException('Network error'));
      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => [testMember]);

      await tester.pumpWidget(createGroupManagementApp());
      await tester.pumpAndSettle();
      final addButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'グループ追加'),
      );

      expect(addButton.onPressed, isNull);
      await tester.tap(find.text('グループ追加'));
      await tester.pumpAndSettle();

      verifyNever(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      );
      expect(find.text('グループ編集'), findsNothing);
    });

    testWidgets('リフレッシュ機能が動作すること', (WidgetTester tester) async {
      // Arrange
      final managedGroupsWithMembers = [groupWithMembers1];

      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => managedGroupsWithMembers);

      // Act
      await tester.pumpWidget(createGroupManagementApp());

      await tester.pumpAndSettle();

      // リフレッシュ実行
      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      // Assert
      verify(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).called(2);
    });

    testWidgets('リフレッシュ失敗時は例外をUI内で処理してエラーを表示すること', (WidgetTester tester) async {
      final managedGroupsWithMembers = [groupWithMembers1];
      var callCount = 0;
      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return managedGroupsWithMembers;
        }
        throw TestException('再取得失敗');
      });

      await tester.pumpWidget(createGroupManagementApp());
      await tester.pumpAndSettle();

      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(
        find.text('データの読み込みに失敗しました: TestException: 再取得失敗'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('削除ボタンが表示されること', (WidgetTester tester) async {
      // Arrange
      final managedGroupsWithMembers = [groupWithMembers1];

      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => managedGroupsWithMembers);

      // Act
      await tester.pumpWidget(createGroupManagementApp());

      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('グループ一覧の行をタップして編集画面が開けること', (WidgetTester tester) async {
      // Arrange
      final managedGroupsWithMembers = [groupWithMembers1];
      final availableMembers = [testMember];

      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => managedGroupsWithMembers);

      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => availableMembers);

      // Act
      await tester.pumpWidget(createGroupManagementApp());

      await tester.pumpAndSettle();

      // ListTileをタップ
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      // Assert - 編集モーダルが開かれることを期待
      expect(find.text('グループ編集'), findsOneWidget);
    });

    testWidgets('メンバー候補の取得中にグループ行を連続タップしても編集画面を1つだけ開くこと', (
      WidgetTester tester,
    ) async {
      final availableMembersCompleter = Completer<List<MemberDto>>();
      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => [groupWithMembers1]);
      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) => availableMembersCompleter.future);

      await tester.pumpWidget(createGroupManagementApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile));
      await tester.tap(find.byType(ListTile));

      verify(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).called(1);

      availableMembersCompleter.complete([testMember]);
      await tester.pumpAndSettle();

      expect(find.text('グループ編集'), findsOneWidget);
    });

    testWidgets('メンバー候補の取得中に削除ボタンを押しても削除確認を開かないこと', (
      WidgetTester tester,
    ) async {
      final availableMembersCompleter = Completer<List<MemberDto>>();
      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => [groupWithMembers1]);
      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) => availableMembersCompleter.future);
      await tester.pumpWidget(createGroupManagementApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile));
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      availableMembersCompleter.complete([testMember]);
      await tester.pumpAndSettle();

      expect(find.text('グループ削除'), findsNothing);
      verifyNever(mockGroupRepository.deleteGroup(groupWithMembers1.id));
      expect(find.text('グループ編集'), findsOneWidget);
    });

    testWidgets('メンバー候補の取得中に再読み込みしても一覧を再取得しないこと', (WidgetTester tester) async {
      final availableMembersCompleter = Completer<List<MemberDto>>();
      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => [groupWithMembers1]);
      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) => availableMembersCompleter.future);

      await tester.pumpWidget(createGroupManagementApp());
      await tester.pumpAndSettle();
      final groupTile = tester.widget<ListTile>(find.byType(ListTile));
      final refreshIndicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );

      groupTile.onTap?.call();
      await tester.pump();
      await refreshIndicator.onRefresh();

      availableMembersCompleter.complete([testMember]);
      await tester.pumpAndSettle();

      verify(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).called(1);
      expect(find.text('グループ編集'), findsOneWidget);
    });

    testWidgets('再読み込み中にグループ行をタップしてもメンバー候補を取得しないこと', (
      WidgetTester tester,
    ) async {
      final refreshCompleter = Completer<List<GroupDto>>();
      var loadCount = 0;
      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) {
        loadCount++;
        if (loadCount == 1) {
          return Future.value([groupWithMembers1]);
        }
        return refreshCompleter.future;
      });
      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => [testMember]);

      await tester.pumpWidget(createGroupManagementApp());
      await tester.pumpAndSettle();
      final groupTile = tester.widget<ListTile>(find.byType(ListTile));
      final refreshIndicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );

      final refreshFuture = refreshIndicator.onRefresh();
      await tester.pump();
      groupTile.onTap?.call();
      await tester.pump();

      refreshCompleter.complete([groupWithMembers1]);
      await refreshFuture;
      await tester.pumpAndSettle();

      verifyNever(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      );
      expect(find.text('グループ編集'), findsNothing);
    });

    testWidgets('再読み込み中に削除ボタンを押しても削除確認を開かないこと', (WidgetTester tester) async {
      final refreshCompleter = Completer<List<GroupDto>>();
      var loadCount = 0;
      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) {
        loadCount++;
        if (loadCount == 1) {
          return Future.value([groupWithMembers1]);
        }
        return refreshCompleter.future;
      });

      await tester.pumpWidget(createGroupManagementApp());
      await tester.pumpAndSettle();
      final deleteButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.delete),
      );
      final refreshIndicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );

      final refreshFuture = refreshIndicator.onRefresh();
      await tester.pump();
      deleteButton.onPressed?.call();
      await tester.pump();

      expect(find.text('グループ削除'), findsNothing);

      refreshCompleter.complete([groupWithMembers1]);
      await refreshFuture;
      await tester.pumpAndSettle();
    });

    testWidgets('削除処理中にグループ行をタップしてもメンバー候補を取得しないこと', (
      WidgetTester tester,
    ) async {
      final deleteTripEntriesCompleter = Completer<void>();
      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => [groupWithMembers1]);
      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => [testMember]);
      when(
        mockTripEntryRepository.deleteTripEntriesByGroupId(
          groupWithMembers1.id,
        ),
      ).thenAnswer((_) => deleteTripEntriesCompleter.future);
      when(
        mockGroupEventRepository.deleteGroupEventsByGroupId(
          groupWithMembers1.id,
        ),
      ).thenAnswer((_) async {});
      when(
        mockGroupRepository.deleteGroup(groupWithMembers1.id),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(createGroupManagementApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ListTile));
      await tester.pump();

      deleteTripEntriesCompleter.complete();
      await tester.pumpAndSettle();

      verifyNever(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      );
      expect(find.text('グループ編集'), findsNothing);
    });

    testWidgets('メンバー候補の取得失敗時は編集画面を開かずエラーを表示すること', (WidgetTester tester) async {
      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => [groupWithMembers1]);
      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenThrow(TestException('メンバー取得失敗'));

      await tester.pumpWidget(createGroupManagementApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.text('グループ編集'), findsNothing);
      expect(
        find.text(
          'メンバー情報の取得に失敗しました: '
          'TestException: メンバー取得失敗',
        ),
        findsOneWidget,
      );
    });

    testWidgets('グループ情報の更新ができること', (WidgetTester tester) async {
      // Arrange
      final managedGroupsWithMembers = [groupWithMembers1];

      final availableMembers = [testMember];

      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => managedGroupsWithMembers);

      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => availableMembers);
      when(mockGroupRepository.updateGroup(any)).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createGroupManagementApp());

      await tester.pumpAndSettle();

      // ListTileをタップして編集モーダルを開く
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      // グループ名を変更
      await tester.enterText(
        find.widgetWithText(TextFormField, 'グループ名').first,
        'Updated Group Name',
      );

      // 更新ボタンをタップ
      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      // Assert - 更新処理が呼ばれることを確認
      verify(mockGroupRepository.updateGroup(any)).called(1);
    });

    testWidgets('グループ更新失敗時は編集画面を維持してエラーを表示すること', (WidgetTester tester) async {
      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => [groupWithMembers1]);
      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => [testMember]);
      when(
        mockGroupRepository.updateGroup(any),
      ).thenThrow(TestException('更新エラー'));

      await tester.pumpWidget(createGroupManagementApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'グループ名').first,
        'Updated Group Name',
      );
      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      expect(find.text('グループ編集'), findsOneWidget);
      expect(find.text('更新に失敗しました: TestException: 更新エラー'), findsOneWidget);
      expect(find.text('保存に失敗しました。もう一度お試しください。'), findsNothing);
    });

    testWidgets('グループ編集後に一覧が最新情報で再取得されること', (WidgetTester tester) async {
      // Arrange
      final managedGroupsWithMembers = [groupWithMembers1];
      final updatedGroups = [
        groupWithMembers1.copyWith(name: 'Updated Group Name'),
      ];
      final availableMembers = [testMember];

      var callCount = 0;
      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? managedGroupsWithMembers : updatedGroups;
      });

      when(
        mockMemberQueryService.getMembersByOwnerId(
          testMember.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => availableMembers);

      when(mockGroupRepository.updateGroup(any)).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createGroupManagementApp());
      await tester.pumpAndSettle();

      // 初期状態の確認
      expect(find.text('Test Group 1'), findsOneWidget);
      expect(find.text('Updated Group Name'), findsNothing);

      // 編集モーダルを開いて更新
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'グループ名').first,
        'Updated Group Name',
      );
      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockGroupRepository.updateGroup(any)).called(1);
      verify(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).called(2);
      expect(find.text('Updated Group Name'), findsOneWidget);
      expect(find.text('Test Group 1'), findsNothing);
    });

    testWidgets('グループ削除時にエラーが発生した場合、エラーメッセージが表示されること', (
      WidgetTester tester,
    ) async {
      // Arrange
      final managedGroupsWithMembers = [groupWithMembers1];

      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => managedGroupsWithMembers);

      when(
        mockTripEntryRepository.deleteTripEntriesByGroupId('group-1'),
      ).thenAnswer((_) async {});

      when(
        mockGroupEventRepository.deleteGroupEventsByGroupId('group-1'),
      ).thenAnswer((_) async {});

      // グループ削除でエラーが発生
      when(
        mockGroupRepository.deleteGroup('group-1'),
      ).thenThrow(TestException('削除エラー'));

      // Act
      await tester.pumpWidget(createGroupManagementApp());

      await tester.pumpAndSettle();

      // 削除ボタンをタップ
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // 確認ダイアログで削除ボタンをタップ
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();

      // Assert - エラーメッセージが表示されることを確認
      expect(find.text('削除に失敗しました: TestException: 削除エラー'), findsOneWidget);
      verify(
        mockTripEntryRepository.deleteTripEntriesByGroupId('group-1'),
      ).called(1);
      verify(
        mockGroupEventRepository.deleteGroupEventsByGroupId('group-1'),
      ).called(1);
      verify(mockGroupRepository.deleteGroup('group-1')).called(1);
    });
  });
}
