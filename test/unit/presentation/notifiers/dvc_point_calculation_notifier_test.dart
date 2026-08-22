import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/usecases/dvc/delete_dvc_limited_point_usecase.dart';
import 'package:memora/application/usecases/dvc/get_dvc_limited_points_usecase.dart';
import 'package:memora/application/usecases/dvc/get_dvc_point_contracts_usecase.dart';
import 'package:memora/application/usecases/dvc/get_dvc_point_usages_usecase.dart';
import 'package:memora/application/usecases/dvc/save_dvc_limited_point_usecase.dart';
import 'package:memora/application/usecases/dvc/save_dvc_point_contracts_usecase.dart';
import 'package:memora/application/usecases/group/get_group_with_members_by_id_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/presentation/features/dvc/dvc_point_usage_mutation_coordinator.dart';
import 'package:memora/presentation/notifiers/dvc_point_calculation_notifier.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/test_exception.dart';
import 'dvc_point_calculation_notifier_test.mocks.dart';

@GenerateMocks([
  GetGroupWithMembersByIdUsecase,
  GetDvcPointContractsUsecase,
  GetDvcLimitedPointsUsecase,
  GetDvcPointUsagesUsecase,
  SaveDvcPointContractsUsecase,
  SaveDvcLimitedPointUsecase,
  DeleteDvcLimitedPointUsecase,
  DvcPointUsageMutationCoordinator,
])
void main() {
  const groupId = 'group-1';
  final currentMonth = DateTime(2025, 1);
  const groupDto = GroupDto(
    id: groupId,
    ownerId: 'member-1',
    name: '家族',
    members: [],
  );
  final contract = DvcPointContractDto(
    id: 'contract-1',
    groupId: groupId,
    contractName: '契約A',
    contractStartYearMonth: currentMonth,
    contractEndYearMonth: currentMonth,
    useYearStartMonth: currentMonth.month,
    annualPoint: 100,
  );
  final limitedPoint = DvcLimitedPointDto(
    id: 'limited-1',
    groupId: groupId,
    startYearMonth: currentMonth,
    endYearMonth: currentMonth,
    point: 30,
  );
  final pointUsage = DvcPointUsageDto(
    id: 'usage-1',
    groupId: groupId,
    usageYearMonth: currentMonth,
    usedPoint: 10,
  );

  late MockGetGroupWithMembersByIdUsecase getGroupUsecase;
  late MockGetDvcPointContractsUsecase getContractsUsecase;
  late MockGetDvcLimitedPointsUsecase getLimitedPointsUsecase;
  late MockGetDvcPointUsagesUsecase getPointUsagesUsecase;
  late MockSaveDvcPointContractsUsecase saveContractsUsecase;
  late MockSaveDvcLimitedPointUsecase saveLimitedPointUsecase;
  late MockDeleteDvcLimitedPointUsecase deleteLimitedPointUsecase;
  late MockDvcPointUsageMutationCoordinator pointUsageMutationCoordinator;
  late ProviderContainer container;

  setUp(() {
    AppLogger.suppressLogging(true);
    getGroupUsecase = MockGetGroupWithMembersByIdUsecase();
    getContractsUsecase = MockGetDvcPointContractsUsecase();
    getLimitedPointsUsecase = MockGetDvcLimitedPointsUsecase();
    getPointUsagesUsecase = MockGetDvcPointUsagesUsecase();
    saveContractsUsecase = MockSaveDvcPointContractsUsecase();
    saveLimitedPointUsecase = MockSaveDvcLimitedPointUsecase();
    deleteLimitedPointUsecase = MockDeleteDvcLimitedPointUsecase();
    pointUsageMutationCoordinator = MockDvcPointUsageMutationCoordinator();
    container = ProviderContainer(
      overrides: [
        appClockProvider.overrideWithValue(FixedAppClock(currentMonth)),
        getGroupWithMembersByIdUsecaseProvider.overrideWithValue(
          getGroupUsecase,
        ),
        getDvcPointContractsUsecaseProvider.overrideWithValue(
          getContractsUsecase,
        ),
        getDvcLimitedPointsUsecaseProvider.overrideWithValue(
          getLimitedPointsUsecase,
        ),
        getDvcPointUsagesUsecaseProvider.overrideWithValue(
          getPointUsagesUsecase,
        ),
        saveDvcPointContractsUsecaseProvider.overrideWithValue(
          saveContractsUsecase,
        ),
        saveDvcLimitedPointUsecaseProvider.overrideWithValue(
          saveLimitedPointUsecase,
        ),
        deleteDvcLimitedPointUsecaseProvider.overrideWithValue(
          deleteLimitedPointUsecase,
        ),
        dvcPointUsageMutationCoordinatorProvider.overrideWithValue(
          pointUsageMutationCoordinator,
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    AppLogger.suppressLogging(false);
  });

  ProviderSubscription<DvcPointCalculationState> listenProvider() {
    final subscription = container.listen(
      dvcPointCalculationNotifierProvider(groupId),
      (_, _) {},
    );
    addTearDown(subscription.close);
    return subscription;
  }

  Future<void> waitForInitialLoad() async {
    final completer = Completer<void>();
    final subscription = container.listen(
      dvcPointCalculationNotifierProvider(groupId),
      (_, next) {
        if (!next.isInitialLoading && !completer.isCompleted) {
          completer.complete();
        }
      },
      fireImmediately: true,
    );
    await completer.future;
    subscription.close();
  }

  void stubInitialLoad({
    List<DvcPointContractDto>? contracts,
    List<DvcLimitedPointDto>? limitedPoints,
    List<DvcPointUsageDto>? pointUsages,
  }) {
    when(getGroupUsecase.execute(groupId)).thenAnswer((_) async => groupDto);
    when(
      getContractsUsecase.execute(groupId),
    ).thenAnswer((_) async => contracts ?? [contract]);
    when(
      getLimitedPointsUsecase.execute(groupId),
    ).thenAnswer((_) async => limitedPoints ?? [limitedPoint]);
    when(
      getPointUsagesUsecase.execute(groupId),
    ).thenAnswer((_) async => pointUsages ?? [pointUsage]);
  }

  Future<DvcPointCalculationNotifier> startNotifier() async {
    stubInitialLoad();
    listenProvider();
    await waitForInitialLoad();
    return container.read(
      dvcPointCalculationNotifierProvider(groupId).notifier,
    );
  }

  group('DvcPointCalculationNotifier', () {
    test('グループと3種類のポイントデータを並行取得し、取得元ごとに完了状態を反映する', () async {
      final groupCompleter = Completer<GroupDto?>();
      final contractsCompleter = Completer<List<DvcPointContractDto>>();
      final limitedPointsCompleter = Completer<List<DvcLimitedPointDto>>();
      final pointUsagesCompleter = Completer<List<DvcPointUsageDto>>();
      when(
        getGroupUsecase.execute(groupId),
      ).thenAnswer((_) => groupCompleter.future);
      when(
        getContractsUsecase.execute(groupId),
      ).thenAnswer((_) => contractsCompleter.future);
      when(
        getLimitedPointsUsecase.execute(groupId),
      ).thenAnswer((_) => limitedPointsCompleter.future);
      when(
        getPointUsagesUsecase.execute(groupId),
      ).thenAnswer((_) => pointUsagesCompleter.future);

      listenProvider();
      await container.pump();

      verify(getGroupUsecase.execute(groupId)).called(1);
      verify(getContractsUsecase.execute(groupId)).called(1);
      verify(getLimitedPointsUsecase.execute(groupId)).called(1);
      verify(getPointUsagesUsecase.execute(groupId)).called(1);

      contractsCompleter.complete([contract]);
      await container.pump();

      var state = container.read(dvcPointCalculationNotifierProvider(groupId));
      expect(state.contracts, [contract]);
      expect(state.contractsStatus, DvcPointDataLoadStatus.success);
      expect(state.groupStatus, DvcPointDataLoadStatus.initialLoading);
      expect(state.calculationResult, isNull);

      groupCompleter.complete(groupDto);
      limitedPointsCompleter.complete([limitedPoint]);
      pointUsagesCompleter.complete([pointUsage]);
      await container.pump();

      state = container.read(dvcPointCalculationNotifierProvider(groupId));
      expect(state.group, groupDto);
      expect(state.limitedPoints, [limitedPoint]);
      expect(state.pointUsages, [pointUsage]);
      expect(state.isInitialLoading, isFalse);
      expect(state.calculationResult, isNotNull);
    });

    test('表示期間の変更ではデータを再取得せず、取得済みデータから再計算する', () async {
      final notifier = await startNotifier();
      clearInteractions(getGroupUsecase);
      clearInteractions(getContractsUsecase);
      clearInteractions(getLimitedPointsUsecase);
      clearInteractions(getPointUsagesUsecase);
      final before = container.read(
        dvcPointCalculationNotifierProvider(groupId),
      );

      notifier.showMorePast();
      notifier.showMoreFuture();

      final after = container.read(
        dvcPointCalculationNotifierProvider(groupId),
      );
      expect(after.visibleStartYearMonth, DateTime(2020, 1));
      expect(after.visibleEndYearMonth, DateTime(2035, 1));
      expect(
        after.calculationResult?.monthlySummaries.length,
        greaterThan(before.calculationResult!.monthlySummaries.length),
      );
      verifyNever(getGroupUsecase.execute(any));
      verifyNever(getContractsUsecase.execute(any));
      verifyNever(getLimitedPointsUsecase.execute(any));
      verifyNever(getPointUsagesUsecase.execute(any));
    });

    test('初期取得中の表示期間変更では未取得データから計算結果を作らない', () async {
      final limitedPointsCompleter = Completer<List<DvcLimitedPointDto>>();
      final pointUsagesCompleter = Completer<List<DvcPointUsageDto>>();
      when(getGroupUsecase.execute(groupId)).thenAnswer((_) async => groupDto);
      when(
        getContractsUsecase.execute(groupId),
      ).thenAnswer((_) async => [contract]);
      when(
        getLimitedPointsUsecase.execute(groupId),
      ).thenAnswer((_) => limitedPointsCompleter.future);
      when(
        getPointUsagesUsecase.execute(groupId),
      ).thenAnswer((_) => pointUsagesCompleter.future);
      listenProvider();
      await container.pump();
      final notifier = container.read(
        dvcPointCalculationNotifierProvider(groupId).notifier,
      );

      notifier.showMorePast();

      var state = container.read(dvcPointCalculationNotifierProvider(groupId));
      expect(state.visibleStartYearMonth, DateTime(2020, 1));
      expect(state.calculationResult, isNull);

      limitedPointsCompleter.complete([limitedPoint]);
      pointUsagesCompleter.complete([pointUsage]);
      await waitForInitialLoad();

      state = container.read(dvcPointCalculationNotifierProvider(groupId));
      expect(state.calculationResult, isNotNull);
      expect(
        state.calculationResult!.monthlySummaries.first.yearMonth,
        DateTime(2020, 1),
      );
    });

    test('契約保存後は契約だけを再取得して再計算する', () async {
      final notifier = await startNotifier();
      clearInteractions(getGroupUsecase);
      clearInteractions(getContractsUsecase);
      clearInteractions(getLimitedPointsUsecase);
      clearInteractions(getPointUsagesUsecase);
      when(
        saveContractsUsecase.execute(groupId: groupId, contracts: [contract]),
      ).thenAnswer((_) async {});
      when(
        getContractsUsecase.execute(groupId),
      ).thenAnswer((_) async => const []);

      expect(await notifier.saveContracts([contract]), isTrue);

      expect(
        container.read(dvcPointCalculationNotifierProvider(groupId)).contracts,
        isEmpty,
      );
      verifyInOrder([
        saveContractsUsecase.execute(groupId: groupId, contracts: [contract]),
        getContractsUsecase.execute(groupId),
      ]);
      verifyNever(getGroupUsecase.execute(any));
      verifyNever(getLimitedPointsUsecase.execute(any));
      verifyNever(getPointUsagesUsecase.execute(any));
    });

    test('期間限定ポイント保存後の再取得失敗では既存データを維持する', () async {
      final notifier = await startNotifier();
      when(
        saveLimitedPointUsecase.execute(limitedPoint),
      ).thenAnswer((_) async {});
      when(
        getLimitedPointsUsecase.execute(groupId),
      ).thenThrow(TestException('再取得失敗'));

      expect(await notifier.saveLimitedPoint(limitedPoint), isTrue);

      final state = container.read(
        dvcPointCalculationNotifierProvider(groupId),
      );
      expect(state.limitedPoints, [limitedPoint]);
      expect(state.limitedPointsStatus, DvcPointDataLoadStatus.error);
      expect(state.calculationResult, isNotNull);
    });

    test('期間限定ポイント削除後は期間限定ポイントだけを再取得する', () async {
      final notifier = await startNotifier();
      clearInteractions(getContractsUsecase);
      clearInteractions(getLimitedPointsUsecase);
      clearInteractions(getPointUsagesUsecase);
      when(
        deleteLimitedPointUsecase.execute(limitedPoint.id),
      ).thenAnswer((_) async {});
      when(
        getLimitedPointsUsecase.execute(groupId),
      ).thenAnswer((_) async => const []);

      expect(await notifier.deleteLimitedPoint(limitedPoint.id), isTrue);

      expect(
        container
            .read(dvcPointCalculationNotifierProvider(groupId))
            .limitedPoints,
        isEmpty,
      );
      verifyInOrder([
        deleteLimitedPointUsecase.execute(limitedPoint.id),
        getLimitedPointsUsecase.execute(groupId),
      ]);
      verifyNever(getContractsUsecase.execute(any));
      verifyNever(getPointUsagesUsecase.execute(any));
    });

    test('利用ポイント保存後は利用ポイントだけを再取得する', () async {
      final notifier = await startNotifier();
      clearInteractions(getContractsUsecase);
      clearInteractions(getLimitedPointsUsecase);
      clearInteractions(getPointUsagesUsecase);
      when(
        pointUsageMutationCoordinator.saveDvcPointUsage(pointUsage),
      ).thenAnswer((_) async {});
      when(
        getPointUsagesUsecase.execute(groupId),
      ).thenAnswer((_) async => const []);

      expect(await notifier.savePointUsage(pointUsage), isTrue);

      expect(
        container
            .read(dvcPointCalculationNotifierProvider(groupId))
            .pointUsages,
        isEmpty,
      );
      verifyInOrder([
        pointUsageMutationCoordinator.saveDvcPointUsage(pointUsage),
        getPointUsagesUsecase.execute(groupId),
      ]);
      verifyNever(getContractsUsecase.execute(any));
      verifyNever(getLimitedPointsUsecase.execute(any));
    });

    test('利用ポイント削除中の再試行と重複する更新を無視する', () async {
      final notifier = await startNotifier();
      final deleteCompleter = Completer<void>();
      when(
        pointUsageMutationCoordinator.deleteDvcPointUsage(pointUsage.id),
      ).thenAnswer((_) => deleteCompleter.future);
      when(
        getPointUsagesUsecase.execute(groupId),
      ).thenAnswer((_) async => const []);

      final firstDelete = notifier.deletePointUsage(pointUsage.id);

      expect(await notifier.retryPointUsages(), isFalse);
      expect(await notifier.deletePointUsage(pointUsage.id), isFalse);
      verify(
        pointUsageMutationCoordinator.deleteDvcPointUsage(pointUsage.id),
      ).called(1);

      deleteCompleter.complete();
      expect(await firstDelete, isTrue);
    });

    test('取得失敗したデータだけを再試行できる', () async {
      when(getGroupUsecase.execute(groupId)).thenAnswer((_) async => groupDto);
      when(
        getContractsUsecase.execute(groupId),
      ).thenThrow(TestException('契約取得失敗'));
      when(
        getLimitedPointsUsecase.execute(groupId),
      ).thenAnswer((_) async => [limitedPoint]);
      when(
        getPointUsagesUsecase.execute(groupId),
      ).thenAnswer((_) async => [pointUsage]);
      listenProvider();
      await waitForInitialLoad();
      final notifier = container.read(
        dvcPointCalculationNotifierProvider(groupId).notifier,
      );
      clearInteractions(getGroupUsecase);
      clearInteractions(getContractsUsecase);
      clearInteractions(getLimitedPointsUsecase);
      clearInteractions(getPointUsagesUsecase);
      when(
        getContractsUsecase.execute(groupId),
      ).thenAnswer((_) async => [contract]);

      expect(await notifier.retryContracts(), isTrue);

      final state = container.read(
        dvcPointCalculationNotifierProvider(groupId),
      );
      expect(state.contracts, [contract]);
      expect(state.contractsStatus, DvcPointDataLoadStatus.success);
      expect(state.calculationResult, isNotNull);
      verify(getContractsUsecase.execute(groupId)).called(1);
      verifyNever(getGroupUsecase.execute(any));
      verifyNever(getLimitedPointsUsecase.execute(any));
      verifyNever(getPointUsagesUsecase.execute(any));
    });
  });
}
