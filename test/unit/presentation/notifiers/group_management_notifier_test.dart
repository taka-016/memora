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
  const secondMember = MemberDto(id: 'member-3', displayName: '次郎');
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
  const secondMemberGroup = GroupDto(
    id: 'group-2',
    ownerId: 'member-3',
    name: '次郎の家族',
    members: [],
  );

  late MockGetManagedGroupsWithMembersUsecase getGroupsUsecase;
  late MockGetManagedMembersUsecase getMembersUsecase;
  late MockCreateGroupUsecase createGroupUsecase;
  late MockUpdateGroupUsecase updateGroupUsecase;
  late MockDeleteGroupUsecase deleteGroupUsecase;
  late ProviderContainer container;

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
  });

  tearDown(() {
    container.dispose();
  });

  Future<GroupManagementNotifier> startNotifier({
    List<GroupDto> groups = const [managedGroup],
  }) async {
    when(
      getGroupsUsecase.execute(currentMember),
    ).thenAnswer((_) async => groups);
    final provider = groupManagementNotifierProvider(currentMember);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(provider.future);
    return container.read(provider.notifier);
  }

  group('GroupManagementNotifier', () {
    test('初期取得中から取得成功へ遷移する', () async {
      final completer = Completer<List<GroupDto>>();
      when(
        getGroupsUsecase.execute(currentMember),
      ).thenAnswer((_) => completer.future);
      final provider = groupManagementNotifierProvider(currentMember);
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);

      expect(container.read(provider).isLoading, isTrue);

      completer.complete(const [managedGroup]);
      await container.read(provider.future);

      final state = container.read(provider);
      expect(state.hasValue, isTrue);
      expect(state.requireValue.groups, const [managedGroup]);
      expect(state.requireValue.errorMessage, isEmpty);
    });

    test('初期取得失敗時はAsyncErrorへ遷移し、自動再試行しない', () async {
      when(
        getGroupsUsecase.execute(currentMember),
      ).thenThrow(TestException('取得失敗'));
      final provider = groupManagementNotifierProvider(currentMember);
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);

      await expectLater(
        container.read(provider.future),
        throwsA(isA<TestException>()),
      );

      final state = container.read(provider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<TestException>());
      verify(getGroupsUsecase.execute(currentMember)).called(1);
    });

    test('再取得中は既存一覧を維持し、成功後に一覧を更新する', () async {
      await startNotifier();
      final provider = groupManagementNotifierProvider(currentMember);
      final completer = Completer<List<GroupDto>>();
      when(
        getGroupsUsecase.execute(currentMember),
      ).thenAnswer((_) => completer.future);

      final refreshFuture = container.refresh(provider.future);
      await container.pump();

      final refreshingState = container.read(provider);
      expect(refreshingState.isRefreshing, isTrue);
      expect(refreshingState.value?.groups, const [managedGroup]);

      completer.complete(const [updatedGroup]);
      await refreshFuture;

      expect(container.read(provider).requireValue.groups, const [
        updatedGroup,
      ]);
    });

    test('再取得失敗時は既存一覧を維持してAsyncErrorへ遷移する', () async {
      await startNotifier();
      final provider = groupManagementNotifierProvider(currentMember);
      when(
        getGroupsUsecase.execute(currentMember),
      ).thenThrow(TestException('再取得失敗'));

      await expectLater(
        container.refresh(provider.future),
        throwsA(isA<TestException>()),
      );

      final state = container.read(provider);
      expect(state.hasError, isTrue);
      expect(state.value?.groups, const [managedGroup]);
    });

    test('メンバーごとにProviderの状態を分離する', () async {
      final firstCompleter = Completer<List<GroupDto>>();
      when(
        getGroupsUsecase.execute(currentMember),
      ).thenAnswer((_) => firstCompleter.future);
      when(
        getGroupsUsecase.execute(secondMember),
      ).thenAnswer((_) async => const [secondMemberGroup]);
      final firstProvider = groupManagementNotifierProvider(currentMember);
      final secondProvider = groupManagementNotifierProvider(secondMember);
      final firstSubscription = container.listen(firstProvider, (_, _) {});
      final secondSubscription = container.listen(secondProvider, (_, _) {});
      addTearDown(firstSubscription.close);
      addTearDown(secondSubscription.close);

      await container.read(secondProvider.future);

      expect(container.read(firstProvider).isLoading, isTrue);
      expect(container.read(secondProvider).requireValue.groups, const [
        secondMemberGroup,
      ]);

      firstCompleter.complete(const [managedGroup]);
      await container.read(firstProvider.future);

      expect(container.read(firstProvider).requireValue.groups, const [
        managedGroup,
      ]);
      expect(container.read(secondProvider).requireValue.groups, const [
        secondMemberGroup,
      ]);
    });

    test('利用可能なメンバーを取得してグループメンバーへ変換する', () async {
      final notifier = await startNotifier();
      final provider = groupManagementNotifierProvider(currentMember);
      final completer = Completer<List<MemberDto>>();
      when(
        getMembersUsecase.execute(currentMember),
      ).thenAnswer((_) => completer.future);

      final loadMembersFuture = notifier.loadAvailableMembers('group-1');

      final loadingState = container.read(provider).requireValue;
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

      final state = container.read(provider).requireValue;
      expect(state.operationStatus, GroupManagementOperationStatus.success);
      expect(state.availableMembers, members);
      expect(members, hasLength(1));
      expect(members!.single.memberId, availableMember.id);
      expect(members.single.groupId, managedGroup.id);
    });

    test('利用可能なメンバーの取得失敗時はエラー状態へ遷移する', () async {
      final notifier = await startNotifier();
      final provider = groupManagementNotifierProvider(currentMember);
      when(
        getMembersUsecase.execute(currentMember),
      ).thenThrow(TestException('メンバー取得失敗'));

      final members = await notifier.loadAvailableMembers(managedGroup.id);

      final state = container.read(provider).requireValue;
      expect(members, isNull);
      expect(state.operationStatus, GroupManagementOperationStatus.error);
      expect(state.errorMessage, 'メンバー情報の取得に失敗しました: TestException: メンバー取得失敗');
    });

    test('破棄済みProviderでは利用可能なメンバーの取得結果を反映しない', () async {
      when(
        getGroupsUsecase.execute(currentMember),
      ).thenAnswer((_) async => const [managedGroup]);
      final provider = groupManagementNotifierProvider(currentMember);
      final subscription = container.listen(provider, (_, _) {});
      await container.read(provider.future);
      final notifier = container.read(provider.notifier);
      final completer = Completer<List<MemberDto>>();
      when(
        getMembersUsecase.execute(currentMember),
      ).thenAnswer((_) => completer.future);

      final membersFuture = notifier.loadAvailableMembers(managedGroup.id);
      subscription.close();
      await container.pump();
      completer.complete(const [availableMember]);

      expect(await membersFuture, isNull);
    });

    test('作成成功後にProviderを再構築して一覧を更新する', () async {
      final notifier = await startNotifier();
      final provider = groupManagementNotifierProvider(currentMember);
      final operationStatuses = <GroupManagementOperationStatus>[];
      final subscription = container.listen(provider, (_, next) {
        final value = next.value;
        if (value != null) {
          operationStatuses.add(value.operationStatus);
        }
      });
      addTearDown(subscription.close);
      when(
        createGroupUsecase.execute(createdGroup),
      ).thenAnswer((_) async => 'group-2');
      when(
        getGroupsUsecase.execute(currentMember),
      ).thenAnswer((_) async => const [managedGroup, createdGroup]);

      final result = await notifier.createGroup(createdGroup);
      await container.read(provider.future);

      expect(result, isTrue);
      expect(
        operationStatuses,
        contains(GroupManagementOperationStatus.loading),
      );
      expect(
        operationStatuses,
        contains(GroupManagementOperationStatus.success),
      );
      expect(container.read(provider).requireValue.groups, const [
        managedGroup,
        createdGroup,
      ]);
      verifyInOrder([
        createGroupUsecase.execute(createdGroup),
        getGroupsUsecase.execute(currentMember),
      ]);
    });

    test('作成失敗時は一覧を再取得せずエラー状態へ遷移する', () async {
      final notifier = await startNotifier();
      final provider = groupManagementNotifierProvider(currentMember);
      clearInteractions(getGroupsUsecase);
      when(
        createGroupUsecase.execute(createdGroup),
      ).thenThrow(TestException('作成失敗'));

      final result = await notifier.createGroup(createdGroup);

      final state = container.read(provider).requireValue;
      expect(result, isFalse);
      expect(state.operationStatus, GroupManagementOperationStatus.error);
      expect(state.groups, const [managedGroup]);
      expect(state.errorMessage, '作成に失敗しました: TestException: 作成失敗');
      verifyNever(getGroupsUsecase.execute(any));
    });

    test('更新成功後にProviderを再構築して一覧を更新する', () async {
      final notifier = await startNotifier();
      final provider = groupManagementNotifierProvider(currentMember);
      when(updateGroupUsecase.execute(updatedGroup)).thenAnswer((_) async {});
      when(
        getGroupsUsecase.execute(currentMember),
      ).thenAnswer((_) async => const [updatedGroup]);

      final result = await notifier.updateGroup(updatedGroup);
      await container.read(provider.future);

      expect(result, isTrue);
      expect(container.read(provider).requireValue.groups, const [
        updatedGroup,
      ]);
      verifyInOrder([
        updateGroupUsecase.execute(updatedGroup),
        getGroupsUsecase.execute(currentMember),
      ]);
    });

    test('更新失敗時は一覧を再取得せずエラー状態へ遷移する', () async {
      final notifier = await startNotifier();
      final provider = groupManagementNotifierProvider(currentMember);
      clearInteractions(getGroupsUsecase);
      when(
        updateGroupUsecase.execute(updatedGroup),
      ).thenThrow(TestException('更新失敗'));

      final result = await notifier.updateGroup(updatedGroup);

      final state = container.read(provider).requireValue;
      expect(result, isFalse);
      expect(state.operationStatus, GroupManagementOperationStatus.error);
      expect(state.groups, const [managedGroup]);
      expect(state.errorMessage, '更新に失敗しました: TestException: 更新失敗');
      verifyNever(getGroupsUsecase.execute(any));
    });

    test('削除成功後にProviderを再構築して一覧を更新する', () async {
      final notifier = await startNotifier();
      final provider = groupManagementNotifierProvider(currentMember);
      when(
        deleteGroupUsecase.execute(managedGroup.id),
      ).thenAnswer((_) async {});
      when(
        getGroupsUsecase.execute(currentMember),
      ).thenAnswer((_) async => const []);

      final result = await notifier.deleteGroup(managedGroup.id);
      await container.read(provider.future);

      expect(result, isTrue);
      expect(container.read(provider).requireValue.groups, isEmpty);
      verifyInOrder([
        deleteGroupUsecase.execute(managedGroup.id),
        getGroupsUsecase.execute(currentMember),
      ]);
    });

    test('削除失敗時は一覧を再取得せずエラー状態へ遷移する', () async {
      final notifier = await startNotifier();
      final provider = groupManagementNotifierProvider(currentMember);
      clearInteractions(getGroupsUsecase);
      when(
        deleteGroupUsecase.execute(managedGroup.id),
      ).thenThrow(TestException('削除失敗'));

      final result = await notifier.deleteGroup(managedGroup.id);

      final state = container.read(provider).requireValue;
      expect(result, isFalse);
      expect(state.operationStatus, GroupManagementOperationStatus.error);
      expect(state.groups, const [managedGroup]);
      expect(state.errorMessage, '削除に失敗しました: TestException: 削除失敗');
      verifyNever(getGroupsUsecase.execute(any));
    });

    test('処理中に同じNotifierへ更新を要求しても重複実行しない', () async {
      final notifier = await startNotifier();
      final provider = groupManagementNotifierProvider(currentMember);
      final completer = Completer<void>();
      when(
        updateGroupUsecase.execute(updatedGroup),
      ).thenAnswer((_) => completer.future);
      when(
        getGroupsUsecase.execute(currentMember),
      ).thenAnswer((_) async => const [updatedGroup]);

      final firstResult = notifier.updateGroup(updatedGroup);
      final secondResult = await notifier.updateGroup(updatedGroup);

      expect(secondResult, isFalse);
      verify(updateGroupUsecase.execute(updatedGroup)).called(1);

      completer.complete();
      expect(await firstResult, isTrue);
      await container.read(provider.future);
    });
  });
}
