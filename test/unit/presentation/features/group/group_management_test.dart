import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_with_members_dto.dart';
import 'package:memora/application/interfaces/group_query_service.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/repositories/group_event_repository.dart';
import 'package:memora/domain/repositories/group_repository.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/presentation/features/group/group_management.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import '../../../../helpers/test_exception.dart';

import 'group_management_test.mocks.dart';

@GenerateMocks([
  GroupRepository,
  GroupEventRepository,
  GroupQueryService,
  MemberRepository,
  TripEntryRepository,
])
void main() {
  late MockGroupRepository mockGroupRepository;
  late MockGroupEventRepository mockGroupEventRepository;
  late MockGroupQueryService mockGroupQueryService;
  late MockMemberRepository mockMemberRepository;
  late MockTripEntryRepository mockTripEntryRepository;
  late Group group1;
  late Member testMember;
  late GroupWithMembersDto groupWithMembers1;
  late GroupWithMembersDto groupWithMembers2;
  late List<Override> providerOverrides;

  setUp(() {
    mockGroupRepository = MockGroupRepository();
    mockGroupEventRepository = MockGroupEventRepository();
    mockGroupQueryService = MockGroupQueryService();
    mockMemberRepository = MockMemberRepository();
    mockTripEntryRepository = MockTripEntryRepository();
    testMember = Member(
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
      passportNumber: null,
      passportExpiration: null,
    );
    groupWithMembers1 = GroupWithMembersDto(
      groupId: 'group-1',
      groupName: 'Test Group 1',
      members: [],
    );
    groupWithMembers2 = GroupWithMembersDto(
      groupId: 'group-2',
      groupName: 'Test Group 2',
      members: [],
    );
    group1 = Group(
      id: 'group-1',
      ownerId: testMember.id,
      name: 'Test Group 1',
      memo: 'Test memo 1',
    );

    providerOverrides = [
      groupRepositoryProvider.overrideWithValue(mockGroupRepository),
      groupEventRepositoryProvider.overrideWithValue(mockGroupEventRepository),
      groupQueryServiceProvider.overrideWithValue(mockGroupQueryService),
      memberRepositoryProvider.overrideWithValue(mockMemberRepository),
      tripEntryRepositoryProvider.overrideWithValue(mockTripEntryRepository),
    ];
  });

  Widget createGroupManagementApp() {
    return ProviderScope(
      overrides: providerOverrides,
      child: MaterialApp(
        home: Scaffold(body: GroupManagement(member: testMember)),
      ),
    );
  }

  group('GroupManagement', () {
    testWidgets('初期化時にグループリストが読み込まれること', (WidgetTester tester) async {
      // Arrange
      final managedGroupsWithMembers = [groupWithMembers1, groupWithMembers2];

      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: [const OrderBy('name', descending: false)],
          membersOrderBy: [const OrderBy('displayName', descending: false)],
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
          groupsOrderBy: [const OrderBy('name', descending: false)],
          membersOrderBy: [const OrderBy('displayName', descending: false)],
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
          groupsOrderBy: [const OrderBy('name', descending: false)],
          membersOrderBy: [const OrderBy('displayName', descending: false)],
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
          groupsOrderBy: [const OrderBy('name', descending: false)],
          membersOrderBy: [const OrderBy('displayName', descending: false)],
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
          groupsOrderBy: [const OrderBy('name', descending: false)],
          membersOrderBy: [const OrderBy('displayName', descending: false)],
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

    testWidgets('リフレッシュ機能が動作すること', (WidgetTester tester) async {
      // Arrange
      final managedGroupsWithMembers = [groupWithMembers1];

      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: [const OrderBy('name', descending: false)],
          membersOrderBy: [const OrderBy('displayName', descending: false)],
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
          groupsOrderBy: [const OrderBy('name', descending: false)],
          membersOrderBy: [const OrderBy('displayName', descending: false)],
        ),
      ).called(2);
    });

    testWidgets('削除ボタンが表示されること', (WidgetTester tester) async {
      // Arrange
      final managedGroupsWithMembers = [groupWithMembers1];

      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: [const OrderBy('name', descending: false)],
          membersOrderBy: [const OrderBy('displayName', descending: false)],
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
          groupsOrderBy: [const OrderBy('name', descending: false)],
          membersOrderBy: [const OrderBy('displayName', descending: false)],
        ),
      ).thenAnswer((_) async => managedGroupsWithMembers);

      when(
        mockGroupRepository.getGroupById(group1.id),
      ).thenAnswer((_) async => group1);

      when(
        mockMemberRepository.getMembersByOwnerId(
          testMember.id,
          orderBy: [const OrderBy('displayName', descending: false)],
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

    testWidgets('グループ情報の更新ができること', (WidgetTester tester) async {
      // Arrange
      final managedGroupsWithMembers = [groupWithMembers1];

      final availableMembers = [testMember];

      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: [const OrderBy('name', descending: false)],
          membersOrderBy: [const OrderBy('displayName', descending: false)],
        ),
      ).thenAnswer((_) async => managedGroupsWithMembers);

      when(
        mockGroupRepository.getGroupById(group1.id),
      ).thenAnswer((_) async => group1);

      when(
        mockMemberRepository.getMembersByOwnerId(
          testMember.id,
          orderBy: [const OrderBy('displayName', descending: false)],
        ),
      ).thenAnswer((_) async => availableMembers);

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

    testWidgets('グループ削除時にエラーが発生した場合、エラーメッセージが表示されること', (
      WidgetTester tester,
    ) async {
      // Arrange
      final managedGroupsWithMembers = [groupWithMembers1];

      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          testMember.id,
          groupsOrderBy: [const OrderBy('name', descending: false)],
          membersOrderBy: [const OrderBy('displayName', descending: false)],
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
