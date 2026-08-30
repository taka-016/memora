import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/usecases/member/create_member_usecase.dart';
import 'package:memora/application/usecases/member/delete_member_usecase.dart';
import 'package:memora/application/usecases/member/get_managed_members_usecase.dart';
import 'package:memora/application/usecases/member/get_member_by_id_usecase.dart';
import 'package:memora/application/usecases/member/update_member_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/notifiers/member/member_management_notifier.dart';

import '../../../../helpers/test_exception.dart';

void main() {
  const currentMember = MemberDto(id: 'member-1', displayName: '太郎');
  const refreshedCurrentMember = MemberDto(
    id: 'member-1',
    displayName: '山田 太郎',
  );
  const managedMember = MemberDto(id: 'member-2', displayName: '花子');
  const updatedManagedMember = MemberDto(id: 'member-2', displayName: '山田 花子');
  const createdMember = MemberDto(id: '', displayName: '次郎');

  late _FakeGetManagedMembersUsecase getManagedMembersUsecase;
  late _FakeGetMemberByIdUseCase getMemberByIdUseCase;
  late _FakeCreateMemberUsecase createMemberUsecase;
  late _FakeUpdateMemberUsecase updateMemberUsecase;
  late _FakeDeleteMemberUsecase deleteMemberUsecase;
  late ProviderContainer container;

  setUp(() {
    AppLogger.suppressLogging(true);
    getManagedMembersUsecase = _FakeGetManagedMembersUsecase();
    getMemberByIdUseCase = _FakeGetMemberByIdUseCase();
    createMemberUsecase = _FakeCreateMemberUsecase();
    updateMemberUsecase = _FakeUpdateMemberUsecase();
    deleteMemberUsecase = _FakeDeleteMemberUsecase();
    container = ProviderContainer(
      overrides: [
        getManagedMembersUsecaseProvider.overrideWithValue(
          getManagedMembersUsecase,
        ),
        getMemberByIdUsecaseProvider.overrideWithValue(getMemberByIdUseCase),
        createMemberUsecaseProvider.overrideWithValue(createMemberUsecase),
        updateMemberUsecaseProvider.overrideWithValue(updateMemberUsecase),
        deleteMemberUsecaseProvider.overrideWithValue(deleteMemberUsecase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  Future<MemberManagementNotifier> startNotifier() async {
    getManagedMembersUsecase.result = const [managedMember];
    getMemberByIdUseCase.result = refreshedCurrentMember;
    final provider = memberManagementNotifierProvider(currentMember);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(provider.future);
    return container.read(provider.notifier);
  }

  group('MemberManagementNotifier', () {
    test('管理対象メンバーと最新の本人メンバーを統合して保持する', () async {
      final calls = <String>[];
      getManagedMembersUsecase
        ..calls = calls
        ..result = const [managedMember];
      getMemberByIdUseCase
        ..calls = calls
        ..result = refreshedCurrentMember;
      final provider = memberManagementNotifierProvider(currentMember);
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);

      await container.read(provider.future);

      expect(container.read(provider).requireValue.members, const [
        refreshedCurrentMember,
        managedMember,
      ]);
      expect(calls, ['管理対象メンバー取得', '本人メンバー取得']);
    });

    test('本人メンバーを解決できない場合はAsyncErrorへ遷移する', () async {
      getManagedMembersUsecase.result = const [managedMember];
      getMemberByIdUseCase.result = null;
      final provider = memberManagementNotifierProvider(currentMember);
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);

      await expectLater(
        container.read(provider.future),
        throwsA(isA<StateError>()),
      );

      expect(container.read(provider).hasError, isTrue);
    });

    test('再取得中は既存一覧を維持し、成功後に一覧を更新する', () async {
      final notifier = await startNotifier();
      final provider = memberManagementNotifierProvider(currentMember);
      final completer = Completer<List<MemberDto>>();
      getManagedMembersUsecase.result = completer.future;
      getMemberByIdUseCase.result = refreshedCurrentMember;

      final refreshResult = notifier.refreshMembers();
      await container.pump();

      final refreshingState = container.read(provider);
      expect(refreshingState.isRefreshing, isTrue);
      expect(refreshingState.value?.members, const [
        refreshedCurrentMember,
        managedMember,
      ]);

      completer.complete(const [updatedManagedMember]);
      expect(await refreshResult, isTrue);

      expect(container.read(provider).requireValue.members, const [
        refreshedCurrentMember,
        updatedManagedMember,
      ]);
    });

    test('再取得失敗時は既存一覧を維持してAsyncErrorへ遷移する', () async {
      final notifier = await startNotifier();
      final provider = memberManagementNotifierProvider(currentMember);
      getManagedMembersUsecase.result = TestException('再取得失敗');

      expect(await notifier.refreshMembers(), isTrue);
      await expectLater(
        container.read(provider.future),
        throwsA(isA<TestException>()),
      );

      final state = container.read(provider);
      expect(state.hasError, isTrue);
      expect(state.value?.members, const [
        refreshedCurrentMember,
        managedMember,
      ]);
    });

    test('作成成功後に一覧を再取得する', () async {
      final calls = <String>[];
      final notifier = await startNotifier();
      final provider = memberManagementNotifierProvider(currentMember);
      getManagedMembersUsecase
        ..calls = calls
        ..result = const [managedMember, createdMember];
      getMemberByIdUseCase
        ..calls = calls
        ..result = refreshedCurrentMember;
      createMemberUsecase.calls = calls;

      expect(await notifier.createMember(createdMember), isTrue);
      await container.read(provider.future);

      expect(container.read(provider).requireValue.members, const [
        refreshedCurrentMember,
        managedMember,
        createdMember,
      ]);
      expect(calls, ['メンバー作成', '管理対象メンバー取得', '本人メンバー取得']);
      expect(createMemberUsecase.ownerIds, [currentMember.id]);
    });

    test('作成失敗時は一覧を再取得せず例外を呼び出し元へ伝播する', () async {
      final notifier = await startNotifier();
      final provider = memberManagementNotifierProvider(currentMember);
      final initialState = container.read(provider).requireValue;
      getManagedMembersUsecase.callCount = 0;
      getMemberByIdUseCase.callCount = 0;
      createMemberUsecase.error = TestException('作成失敗');

      await expectLater(
        notifier.createMember(createdMember),
        throwsA(isA<TestException>()),
      );

      expect(container.read(provider).requireValue, initialState);
      expect(getManagedMembersUsecase.callCount, 0);
      expect(getMemberByIdUseCase.callCount, 0);
    });

    test('更新成功後に本人を含む一覧を再取得する', () async {
      final calls = <String>[];
      final notifier = await startNotifier();
      final provider = memberManagementNotifierProvider(currentMember);
      getManagedMembersUsecase
        ..calls = calls
        ..result = const [updatedManagedMember];
      getMemberByIdUseCase
        ..calls = calls
        ..result = refreshedCurrentMember;
      updateMemberUsecase.calls = calls;

      expect(await notifier.updateMember(updatedManagedMember), isTrue);
      await container.read(provider.future);

      expect(container.read(provider).requireValue.members, const [
        refreshedCurrentMember,
        updatedManagedMember,
      ]);
      expect(calls, ['メンバー更新', '管理対象メンバー取得', '本人メンバー取得']);
    });

    test('削除成功後に一覧を再取得する', () async {
      final calls = <String>[];
      final notifier = await startNotifier();
      final provider = memberManagementNotifierProvider(currentMember);
      getManagedMembersUsecase
        ..calls = calls
        ..result = const <MemberDto>[];
      getMemberByIdUseCase
        ..calls = calls
        ..result = refreshedCurrentMember;
      deleteMemberUsecase.calls = calls;

      expect(await notifier.deleteMember(managedMember.id), isTrue);
      await container.read(provider.future);

      expect(container.read(provider).requireValue.members, const [
        refreshedCurrentMember,
      ]);
      expect(calls, ['メンバー削除', '管理対象メンバー取得', '本人メンバー取得']);
    });

    test('削除失敗時は一覧を再取得せず例外を呼び出し元へ伝播する', () async {
      final notifier = await startNotifier();
      final provider = memberManagementNotifierProvider(currentMember);
      final initialState = container.read(provider).requireValue;
      getManagedMembersUsecase.callCount = 0;
      getMemberByIdUseCase.callCount = 0;
      deleteMemberUsecase.error = TestException('削除失敗');

      await expectLater(
        notifier.deleteMember(managedMember.id),
        throwsA(isA<TestException>()),
      );

      expect(container.read(provider).requireValue, initialState);
      expect(getManagedMembersUsecase.callCount, 0);
      expect(getMemberByIdUseCase.callCount, 0);
    });

    test('更新失敗時は一覧を再取得せず例外を呼び出し元へ伝播する', () async {
      final notifier = await startNotifier();
      final provider = memberManagementNotifierProvider(currentMember);
      final initialState = container.read(provider).requireValue;
      getManagedMembersUsecase.callCount = 0;
      getMemberByIdUseCase.callCount = 0;
      updateMemberUsecase.error = TestException('更新失敗');

      await expectLater(
        notifier.updateMember(updatedManagedMember),
        throwsA(isA<TestException>()),
      );

      expect(container.read(provider).requireValue, initialState);
      expect(getManagedMembersUsecase.callCount, 0);
      expect(getMemberByIdUseCase.callCount, 0);
    });

    test('更新中の再取得要求と重複する更新要求を無視する', () async {
      final notifier = await startNotifier();
      final provider = memberManagementNotifierProvider(currentMember);
      final completer = Completer<void>();
      updateMemberUsecase.result = completer.future;
      getManagedMembersUsecase.result = const [updatedManagedMember];

      final firstUpdate = notifier.updateMember(updatedManagedMember);

      expect(await notifier.refreshMembers(), isFalse);
      expect(await notifier.updateMember(updatedManagedMember), isFalse);
      expect(updateMemberUsecase.callCount, 1);
      expect(getManagedMembersUsecase.callCount, 1);

      completer.complete();
      expect(await firstUpdate, isTrue);
      await container.read(provider.future);
    });

    test('更新後の再取得完了まで操作を排他する', () async {
      final notifier = await startNotifier();
      final provider = memberManagementNotifierProvider(currentMember);
      final refreshCompleter = Completer<List<MemberDto>>();
      getManagedMembersUsecase.result = refreshCompleter.future;
      var updateCompleted = false;

      final updateFuture = notifier.updateMember(updatedManagedMember)
        ..whenComplete(() => updateCompleted = true);
      await container.pump();

      expect(updateCompleted, isFalse);
      expect(await notifier.refreshMembers(), isFalse);
      expect(await notifier.updateMember(updatedManagedMember), isFalse);
      expect(updateMemberUsecase.callCount, 1);

      refreshCompleter.complete(const [updatedManagedMember]);

      expect(await updateFuture, isTrue);
      expect(container.read(provider).requireValue.members, const [
        refreshedCurrentMember,
        updatedManagedMember,
      ]);
    });
  });
}

class _FakeGetManagedMembersUsecase implements GetManagedMembersUsecase {
  Object result = const <MemberDto>[];
  int callCount = 0;
  List<String>? calls;

  @override
  Future<List<MemberDto>> execute(MemberDto ownerMember) async {
    callCount++;
    calls?.add('管理対象メンバー取得');
    final value = result;
    if (value is Future<List<MemberDto>>) {
      return value;
    }
    if (value is List<MemberDto>) {
      return value;
    }
    throw value;
  }
}

class _FakeGetMemberByIdUseCase implements GetMemberByIdUseCase {
  Object? result;
  int callCount = 0;
  List<String>? calls;

  @override
  Future<MemberDto?> execute(String id) async {
    callCount++;
    calls?.add('本人メンバー取得');
    final value = result;
    if (value is Future<MemberDto?>) {
      return value;
    }
    if (value != null && value is! MemberDto) {
      throw value;
    }
    return value as MemberDto?;
  }
}

class _FakeCreateMemberUsecase implements CreateMemberUsecase {
  List<String>? calls;
  final ownerIds = <String>[];
  Object? error;

  @override
  Future<void> execute(MemberDto editedMember, String ownerId) async {
    calls?.add('メンバー作成');
    ownerIds.add(ownerId);
    if (error case final error?) {
      throw error;
    }
  }
}

class _FakeUpdateMemberUsecase implements UpdateMemberUsecase {
  Object result = Future<void>.value();
  Object? error;
  int callCount = 0;
  List<String>? calls;

  @override
  Future<void> execute(MemberDto updatedMember) async {
    callCount++;
    calls?.add('メンバー更新');
    if (error case final error?) {
      throw error;
    }
    final value = result;
    if (value is Future<void>) {
      await value;
    }
  }
}

class _FakeDeleteMemberUsecase implements DeleteMemberUsecase {
  List<String>? calls;
  Object? error;

  @override
  Future<void> execute(String memberId) async {
    calls?.add('メンバー削除');
    if (error case final error?) {
      throw error;
    }
  }
}
