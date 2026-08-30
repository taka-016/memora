import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/usecases/group/create_group_usecase.dart';
import 'package:memora/application/usecases/group/delete_group_usecase.dart';
import 'package:memora/application/usecases/group/get_managed_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/group/update_group_usecase.dart';
import 'package:memora/presentation/notifiers/group/group_management_notifier.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'group_management_notifier_test.mocks.dart';

@GenerateMocks([
  GetManagedGroupsWithMembersUsecase,
  CreateGroupUsecase,
  UpdateGroupUsecase,
  DeleteGroupUsecase,
])
void main() {
  const currentMember = MemberDto(id: 'member-1', displayName: '太郎');
  const secondMember = MemberDto(id: 'member-3', displayName: '次郎');
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
  late MockCreateGroupUsecase createGroupUsecase;
  late MockUpdateGroupUsecase updateGroupUsecase;
  late MockDeleteGroupUsecase deleteGroupUsecase;
  late ProviderContainer container;

  setUp(() {
    getGroupsUsecase = MockGetManagedGroupsWithMembersUsecase();
    createGroupUsecase = MockCreateGroupUsecase();
    updateGroupUsecase = MockUpdateGroupUsecase();
    deleteGroupUsecase = MockDeleteGroupUsecase();
    container = ProviderContainer(
      overrides: [
        getManagedGroupsWithMembersUsecaseProvider.overrideWithValue(
          getGroupsUsecase,
        ),
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
    when(getGroupsUsecase.execute(currentMember))
        .thenAnswer((_) async => groups);
    final provider = groupManagementNotifierProvider(currentMember);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(provider.future);
    return container.read(provider.notifier);
  }

  group('GroupManagementNotifier', () {
    test('初期取得中から取得成功へ遷移する', () async {
      final completer = Completer<List<GroupDto>>();
      when(getGroupsUsecase.execute(currentMember))
          .thenAnswer((_) => completer.future);
      final provider = groupManagementNotifierProvider(currentMember);
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);

      expect(container.read(provider).isLoading, isTrue);

      completer.complete(const [managedGroup]);
      await container.read(provider.future);

      final state = container.read(provider);
      expect(state.hasValue, isTrue);
      expect(state.requireValue.groups, const [managedGroup]);
    });

    test('初期取得失敗時はAsyncErrorへ遷移し、自動再試行しない', () async {
      when(getGroupsUsecase.execute(currentMember))
          .thenThrow(TestException('取得失敗'));
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
      final notifier = await startNotifier();
      final provider = groupManagementNotifierProvider(currentMember);
      final completer = Completer<List<GroupDto>>();
      when(getGroupsUsecase.execute(currentMember))
          .thenAnswer((_) => completer.future);

      final refreshResult = notifier.refreshGroups();
      await container.pump();

      final refreshingState = container.read(provider);
      expect(refreshingState.isRefreshing, isTrue);
      expect(refreshingState.value?.groups, const [managedGroup]);

      completer.complete(const [updatedGroup]);
      expect(await refreshResult, isTrue);

      expect(container.read(provider).requireValue.groups, const [
        updatedGroup,
      ]);
    });

    test('再取得失敗時は既存一覧を維持してAsyncErrorへ遷移する', () async {
      final notifier = await startNotifier();
      final provider = groupManagementNotifierProvider(currentMember);
      when(getGroupsUsecase.execute(currentMember))
          .thenThrow(TestException('再取得失敗'));

      expect(await notifier.refreshGroups(), isTrue);
      await expectLater(
        container.read(provider.future),
        throwsA(isA<TestException>()),
      );

      final state = container.read(provider);
      expect(state.hasError, isTrue);
      expect(state.value?.groups, const [managedGroup]);
    });

    test('メンバーごとにProviderの状態を分離する', () async {
      final firstCompleter = Completer<List<GroupDto>>();
      when(getGroupsUsecase.execute(currentMember))
          .thenAnswer((_) => firstCompleter.future);
      when(getGroupsUsecase.execute(secondMember))
          .thenAnswer((_) async => const [secondMemberGroup]);
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

    test('作成成功後にProviderを再構築して一覧を更新する', () async {
      final notifier = await startNotifier();
      final provider = groupManagementNotifierProvider(currentMember);
      when(createGroupUsecase.execute(createdGroup))
          .thenAnswer((_) async => 'group-2');
      when(getGroupsUsecase.execute(currentMember))
          .thenAnswer((_) async => const [managedGroup, createdGroup]);

      final result = await notifier.createGroup(createdGroup);
      await container.read(provider.future);

      expect(result, isTrue);
      expect(container.read(provider).requireValue.groups, const [
        managedGroup,
        createdGroup,
      ]);
      verifyInOrder([
        createGroupUsecase.execute(createdGroup),
        getGroupsUsecase.execute(currentMember),
      ]);
    });

    test('作成失敗時は一覧を再取得せず例外を呼び出し元へ伝播する', () async {
      final notifier = await startNotifier();
      final provider = groupManagementNotifierProvider(currentMember);
      final initialState = container.read(provider).requireValue;
      clearInteractions(getGroupsUsecase);
      when(createGroupUsecase.execute(createdGroup))
          .thenThrow(TestException('作成失敗'));

      await expectLater(
        notifier.createGroup(createdGroup),
        throwsA(isA<TestException>()),
      );

      expect(container.read(provider).requireValue, initialState);
      verifyNever(getGroupsUsecase.execute(any));
    });

    test('更新成功後にProviderを再構築して一覧を更新する', () async {
      final notifier = await startNotifier();
      final provider = groupManagementNotifierProvider(currentMember);
      when(updateGroupUsecase.execute(updatedGroup)).thenAnswer((_) async {});
      when(getGroupsUsecase.execute(currentMember))
          .thenAnswer((_) async => const [updatedGroup]);

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

    test('更新失敗時は一覧を再取得せず例外を呼び出し元へ伝播する', () async {
      final notifier = await startNotifier();
      final provider = groupManagementNotifierProvider(currentMember);
      final initialState = container.read(provider).requireValue;
      clearInteractions(getGroupsUsecase);
      when(updateGroupUsecase.execute(updatedGroup))
          .thenThrow(TestException('更新失敗'));

      await expectLater(
        notifier.updateGroup(updatedGroup),
        throwsA(isA<TestException>()),
      );

      expect(container.read(provider).requireValue, initialState);
      verifyNever(getGroupsUsecase.execute(any));
    });

    test('削除成功後にProviderを再構築して一覧を更新する', () async {
      final notifier = await startNotifier();
      final provider = groupManagementNotifierProvider(currentMember);
      when(deleteGroupUsecase.execute(managedGroup.id))
          .thenAnswer((_) async {});
      when(getGroupsUsecase.execute(currentMember))
          .thenAnswer((_) async => const []);

      final result = await notifier.deleteGroup(managedGroup.id);
      await container.read(provider.future);

      expect(result, isTrue);
      expect(container.read(provider).requireValue.groups, isEmpty);
      verifyInOrder([
        deleteGroupUsecase.execute(managedGroup.id),
        getGroupsUsecase.execute(currentMember),
      ]);
    });

    test('削除中の再取得要求を無視して削除完了後に一覧を再取得する', () async {
      var isDeleted = false;
      when(getGroupsUsecase.execute(currentMember))
          .thenAnswer((_) async => isDeleted ? const [] : const [managedGroup]);
      final provider = groupManagementNotifierProvider(currentMember);
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(provider.future);
      final notifier = container.read(provider.notifier);
      final deleteCompleter = Completer<void>();
      when(deleteGroupUsecase.execute(managedGroup.id)).thenAnswer((_) async {
        await deleteCompleter.future;
        isDeleted = true;
      });

      final deleteFuture = notifier.deleteGroup(managedGroup.id);

      await notifier.refreshGroups();
      expect(container.read(provider).requireValue.groups, const [
        managedGroup,
      ]);

      deleteCompleter.complete();

      expect(await deleteFuture, isTrue);
      await container.read(provider.future);
      expect(container.read(provider).requireValue.groups, isEmpty);
      verify(getGroupsUsecase.execute(currentMember)).called(2);
    });

    test('削除中に画面を離れて戻っても完了後に一覧を再取得する', () async {
      var isDeleted = false;
      when(getGroupsUsecase.execute(currentMember))
          .thenAnswer((_) async => isDeleted ? const [] : const [managedGroup]);
      final provider = groupManagementNotifierProvider(currentMember);
      final firstSubscription = container.listen(provider, (_, _) {});
      await container.read(provider.future);
      final notifier = container.read(provider.notifier);
      final deleteCompleter = Completer<void>();
      when(deleteGroupUsecase.execute(managedGroup.id)).thenAnswer((_) async {
        await deleteCompleter.future;
        isDeleted = true;
      });

      final deleteFuture = notifier.deleteGroup(managedGroup.id);
      firstSubscription.close();
      await container.pump();

      final secondSubscription = container.listen(provider, (_, _) {});
      addTearDown(secondSubscription.close);
      await container.read(provider.future);
      expect(container.read(provider).requireValue.groups, const [
        managedGroup,
      ]);

      deleteCompleter.complete();

      expect(await deleteFuture, isTrue);
      await container.read(provider.future);
      expect(container.read(provider).requireValue.groups, isEmpty);
    });

    test('削除失敗時は一覧を再取得せず例外を呼び出し元へ伝播する', () async {
      final notifier = await startNotifier();
      final provider = groupManagementNotifierProvider(currentMember);
      final initialState = container.read(provider).requireValue;
      clearInteractions(getGroupsUsecase);
      when(deleteGroupUsecase.execute(managedGroup.id))
          .thenThrow(TestException('削除失敗'));

      await expectLater(
        notifier.deleteGroup(managedGroup.id),
        throwsA(isA<TestException>()),
      );

      expect(container.read(provider).requireValue, initialState);
      verifyNever(getGroupsUsecase.execute(any));
    });

    test('処理中に同じNotifierへ更新を要求しても重複実行しない', () async {
      final notifier = await startNotifier();
      final provider = groupManagementNotifierProvider(currentMember);
      final completer = Completer<void>();
      when(updateGroupUsecase.execute(updatedGroup))
          .thenAnswer((_) => completer.future);
      when(getGroupsUsecase.execute(currentMember))
          .thenAnswer((_) async => const [updatedGroup]);

      final firstResult = notifier.updateGroup(updatedGroup);
      final secondResult = await notifier.updateGroup(updatedGroup);

      expect(secondResult, isFalse);
      verify(updateGroupUsecase.execute(updatedGroup)).called(1);

      completer.complete();
      expect(await firstResult, isTrue);
      await container.read(provider.future);
    });

    test('更新後の再取得完了まで操作を排他する', () async {
      final notifier = await startNotifier();
      final provider = groupManagementNotifierProvider(currentMember);
      final refreshCompleter = Completer<List<GroupDto>>();
      when(updateGroupUsecase.execute(updatedGroup)).thenAnswer((_) async {});
      when(getGroupsUsecase.execute(currentMember))
          .thenAnswer((_) => refreshCompleter.future);
      var updateCompleted = false;

      final updateFuture = notifier.updateGroup(updatedGroup)
        ..whenComplete(() => updateCompleted = true);
      await container.pump();

      expect(updateCompleted, isFalse);
      expect(await notifier.refreshGroups(), isFalse);
      expect(await notifier.updateGroup(updatedGroup), isFalse);
      verify(updateGroupUsecase.execute(updatedGroup)).called(1);

      refreshCompleter.complete(const [updatedGroup]);

      expect(await updateFuture, isTrue);
      expect(container.read(provider).requireValue.groups, const [
        updatedGroup,
      ]);
    });
  });
}
