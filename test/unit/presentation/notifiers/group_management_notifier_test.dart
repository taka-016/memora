import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/usecases/group/create_group_usecase.dart';
import 'package:memora/application/usecases/group/delete_group_usecase.dart';
import 'package:memora/application/usecases/group/get_managed_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/group/update_group_usecase.dart';
import 'package:memora/application/usecases/member/get_managed_members_usecase.dart';
import 'package:memora/presentation/notifiers/group_management_notifier.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/test_exception.dart';
import 'group_management_notifier_test.mocks.dart';

@GenerateMocks([
  GetManagedGroupsWithMembersUsecase,
  GetManagedMembersUsecase,
  CreateGroupUsecase,
  UpdateGroupUsecase,
  DeleteGroupUsecase,
])
void main() {
  const currentMember = MemberDto(id: 'member-1', displayName: '太郎');
  const availableMember = MemberDto(id: 'member-2', displayName: '花子');
  const managedGroup = GroupDto(
    id: 'group-1',
    ownerId: 'member-1',
    name: '家族',
    members: [],
  );
  const updatedGroup = GroupDto(
    id: 'group-1',
    ownerId: 'member-1',
    name: '家族・親戚',
    members: [],
  );
  const createdGroup = GroupDto(
    id: '',
    ownerId: 'member-1',
    name: '友人',
    members: [],
  );

  late MockGetManagedGroupsWithMembersUsecase getGroupsUsecase;
  late MockGetManagedMembersUsecase getMembersUsecase;
  late MockCreateGroupUsecase createGroupUsecase;
  late MockUpdateGroupUsecase updateGroupUsecase;
  late MockDeleteGroupUsecase deleteGroupUsecase;
  late ProviderContainer container;
  late GroupManagementNotifier notifier;

  setUp(() {
    getGroupsUsecase = MockGetManagedGroupsWithMembersUsecase();
    getMembersUsecase = MockGetManagedMembersUsecase();
    createGroupUsecase = MockCreateGroupUsecase();
    updateGroupUsecase = MockUpdateGroupUsecase();
    deleteGroupUsecase = MockDeleteGroupUsecase();
    container = ProviderContainer(
      overrides: [
        getManagedGroupsWithMembersUsecaseProvider.overrideWithValue(
          getGroupsUsecase,
        ),
        getManagedMembersUsecaseProvider.overrideWithValue(getMembersUsecase),
        createGroupUsecaseProvider.overrideWithValue(createGroupUsecase),
        updateGroupUsecaseProvider.overrideWithValue(updateGroupUsecase),
        deleteGroupUsecaseProvider.overrideWithValue(deleteGroupUsecase),
      ],
    );
    notifier = container.read(groupManagementNotifierProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  Future<void> loadGroups([
    List<GroupDto> groups = const [managedGroup],
  ]) async {
    when(
      getGroupsUsecase.execute(currentMember),
    ).thenAnswer((_) async => groups);
    await notifier.load(currentMember);
  }

  group('GroupManagementNotifier', () {
    test('初期取得中から取得成功へ遷移する', () async {
      final completer = Completer<List<GroupDto>>();
      when(
        getGroupsUsecase.execute(currentMember),
      ).thenAnswer((_) => completer.future);

      final loadFuture = notifier.load(currentMember);

      expect(
        container.read(groupManagementNotifierProvider).status,
        GroupManagementStatus.loading,
      );

      completer.complete(const [managedGroup]);
      await loadFuture;

      final state = container.read(groupManagementNotifierProvider);
      expect(state.status, GroupManagementStatus.loaded);
      expect(state.groups, const [managedGroup]);
      expect(state.errorMessage, isEmpty);
    });

    test('初期取得失敗時はエラー状態へ遷移する', () async {
      when(
        getGroupsUsecase.execute(currentMember),
      ).thenThrow(TestException('取得失敗'));

      await notifier.load(currentMember);

      final state = container.read(groupManagementNotifierProvider);
      expect(state.status, GroupManagementStatus.error);
      expect(state.groups, isEmpty);
      expect(state.errorMessage, 'データの読み込みに失敗しました: TestException: 取得失敗');
    });

    test('再取得中は既存一覧を維持し、成功後に一覧を更新する', () async {
      await loadGroups();
      final completer = Completer<List<GroupDto>>();
      when(
        getGroupsUsecase.execute(currentMember),
      ).thenAnswer((_) => completer.future);

      final refreshFuture = notifier.refresh();

      final refreshingState = container.read(groupManagementNotifierProvider);
      expect(
        refreshingState.refreshStatus,
        GroupManagementRefreshStatus.loading,
      );
      expect(refreshingState.groups, const [managedGroup]);

      completer.complete(const [updatedGroup]);
      await refreshFuture;

      final state = container.read(groupManagementNotifierProvider);
      expect(state.refreshStatus, GroupManagementRefreshStatus.idle);
      expect(state.groups, const [updatedGroup]);
      expect(state.errorMessage, isEmpty);
    });

    test('再取得失敗時は既存一覧を維持してエラー状態へ遷移する', () async {
      await loadGroups();
      when(
        getGroupsUsecase.execute(currentMember),
      ).thenThrow(TestException('再取得失敗'));

      await notifier.refresh();

      final state = container.read(groupManagementNotifierProvider);
      expect(state.refreshStatus, GroupManagementRefreshStatus.error);
      expect(state.groups, const [managedGroup]);
      expect(state.errorMessage, 'データの読み込みに失敗しました: TestException: 再取得失敗');
    });

    test('利用可能なメンバーを取得してグループメンバーへ変換する', () async {
      await loadGroups();
      final completer = Completer<List<MemberDto>>();
      when(
        getMembersUsecase.execute(currentMember),
      ).thenAnswer((_) => completer.future);

      final loadMembersFuture = notifier.loadAvailableMembers('group-1');

      final loadingState = container.read(groupManagementNotifierProvider);
      expect(
        loadingState.operationType,
        GroupManagementOperationType.loadAvailableMembers,
      );
      expect(
        loadingState.operationStatus,
        GroupManagementOperationStatus.loading,
      );

      completer.complete(const [availableMember]);
      final members = await loadMembersFuture;

      final state = container.read(groupManagementNotifierProvider);
      expect(state.operationStatus, GroupManagementOperationStatus.success);
      expect(state.availableMembers, members);
      expect(members, hasLength(1));
      expect(members!.single.memberId, availableMember.id);
      expect(members.single.groupId, managedGroup.id);
    });

    test('利用可能なメンバーの取得失敗時はエラー状態へ遷移する', () async {
      await loadGroups();
      when(
        getMembersUsecase.execute(currentMember),
      ).thenThrow(TestException('メンバー取得失敗'));

      final members = await notifier.loadAvailableMembers(managedGroup.id);

      final state = container.read(groupManagementNotifierProvider);
      expect(members, isNull);
      expect(state.operationStatus, GroupManagementOperationStatus.error);
      expect(state.errorMessage, 'メンバー情報の取得に失敗しました: TestException: メンバー取得失敗');
    });

    test('作成後に一覧を再取得して成功状態へ遷移する', () async {
      await loadGroups();
      when(
        createGroupUsecase.execute(createdGroup),
      ).thenAnswer((_) async => 'group-2');
      when(
        getGroupsUsecase.execute(currentMember),
      ).thenAnswer((_) async => const [managedGroup, createdGroup]);

      final result = await notifier.createGroup(createdGroup);

      final state = container.read(groupManagementNotifierProvider);
      expect(result, isTrue);
      expect(state.operationType, GroupManagementOperationType.create);
      expect(state.operationStatus, GroupManagementOperationStatus.success);
      expect(state.groups, const [managedGroup, createdGroup]);
      verifyInOrder([
        createGroupUsecase.execute(createdGroup),
        getGroupsUsecase.execute(currentMember),
      ]);
    });

    test('作成失敗時は一覧を再取得せずエラー状態へ遷移する', () async {
      await loadGroups();
      clearInteractions(getGroupsUsecase);
      when(
        createGroupUsecase.execute(createdGroup),
      ).thenThrow(TestException('作成失敗'));

      final result = await notifier.createGroup(createdGroup);

      final state = container.read(groupManagementNotifierProvider);
      expect(result, isFalse);
      expect(state.operationStatus, GroupManagementOperationStatus.error);
      expect(state.groups, const [managedGroup]);
      expect(state.errorMessage, '作成に失敗しました: TestException: 作成失敗');
      verifyNever(getGroupsUsecase.execute(any));
    });

    test('更新後に一覧を再取得して成功状態へ遷移する', () async {
      await loadGroups();
      when(updateGroupUsecase.execute(updatedGroup)).thenAnswer((_) async {});
      when(
        getGroupsUsecase.execute(currentMember),
      ).thenAnswer((_) async => const [updatedGroup]);

      final result = await notifier.updateGroup(updatedGroup);

      final state = container.read(groupManagementNotifierProvider);
      expect(result, isTrue);
      expect(state.operationType, GroupManagementOperationType.update);
      expect(state.operationStatus, GroupManagementOperationStatus.success);
      expect(state.groups, const [updatedGroup]);
      verifyInOrder([
        updateGroupUsecase.execute(updatedGroup),
        getGroupsUsecase.execute(currentMember),
      ]);
    });

    test('更新失敗時は一覧を再取得せずエラー状態へ遷移する', () async {
      await loadGroups();
      clearInteractions(getGroupsUsecase);
      when(
        updateGroupUsecase.execute(updatedGroup),
      ).thenThrow(TestException('更新失敗'));

      final result = await notifier.updateGroup(updatedGroup);

      final state = container.read(groupManagementNotifierProvider);
      expect(result, isFalse);
      expect(state.operationStatus, GroupManagementOperationStatus.error);
      expect(state.groups, const [managedGroup]);
      expect(state.errorMessage, '更新に失敗しました: TestException: 更新失敗');
      verifyNever(getGroupsUsecase.execute(any));
    });

    test('削除後に一覧を再取得して成功状態へ遷移する', () async {
      await loadGroups();
      when(
        deleteGroupUsecase.execute(managedGroup.id),
      ).thenAnswer((_) async {});
      when(
        getGroupsUsecase.execute(currentMember),
      ).thenAnswer((_) async => const []);

      final result = await notifier.deleteGroup(managedGroup.id);

      final state = container.read(groupManagementNotifierProvider);
      expect(result, isTrue);
      expect(state.operationType, GroupManagementOperationType.delete);
      expect(state.operationStatus, GroupManagementOperationStatus.success);
      expect(state.groups, isEmpty);
      verifyInOrder([
        deleteGroupUsecase.execute(managedGroup.id),
        getGroupsUsecase.execute(currentMember),
      ]);
    });

    test('削除失敗時は一覧を再取得せずエラー状態へ遷移する', () async {
      await loadGroups();
      clearInteractions(getGroupsUsecase);
      when(
        deleteGroupUsecase.execute(managedGroup.id),
      ).thenThrow(TestException('削除失敗'));

      final result = await notifier.deleteGroup(managedGroup.id);

      final state = container.read(groupManagementNotifierProvider);
      expect(result, isFalse);
      expect(state.operationStatus, GroupManagementOperationStatus.error);
      expect(state.groups, const [managedGroup]);
      expect(state.errorMessage, '削除に失敗しました: TestException: 削除失敗');
      verifyNever(getGroupsUsecase.execute(any));
    });

    test('更新後の一覧再取得失敗時は既存一覧を維持してエラー状態へ遷移する', () async {
      await loadGroups();
      when(updateGroupUsecase.execute(updatedGroup)).thenAnswer((_) async {});
      when(
        getGroupsUsecase.execute(currentMember),
      ).thenThrow(TestException('再取得失敗'));

      final result = await notifier.updateGroup(updatedGroup);

      final state = container.read(groupManagementNotifierProvider);
      expect(result, isFalse);
      expect(state.operationStatus, GroupManagementOperationStatus.error);
      expect(state.groups, const [managedGroup]);
      expect(state.errorMessage, '更新に失敗しました: TestException: 再取得失敗');
      verifyInOrder([
        updateGroupUsecase.execute(updatedGroup),
        getGroupsUsecase.execute(currentMember),
      ]);
    });
  });
}
