import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/usecases/dvc/calculate_dvc_point_table_usecase.dart';
import 'package:memora/application/usecases/dvc/delete_dvc_limited_point_usecase.dart';
import 'package:memora/application/usecases/dvc/get_dvc_limited_points_usecase.dart';
import 'package:memora/application/usecases/dvc/get_dvc_point_contracts_usecase.dart';
import 'package:memora/application/usecases/dvc/get_dvc_point_usages_usecase.dart';
import 'package:memora/application/usecases/dvc/save_dvc_limited_point_usecase.dart';
import 'package:memora/application/usecases/dvc/save_dvc_point_contracts_usecase.dart';
import 'package:memora/application/usecases/group/get_group_with_members_by_id_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/presentation/features/dvc/dvc_point_calculation_date_utils.dart';
import 'package:memora/presentation/features/dvc/dvc_point_usage_mutation_coordinator.dart';
import 'package:memora/presentation/notifiers/dvc/dvc_point_calculation_state.dart';

export 'dvc_point_calculation_state.dart';

final dvcPointCalculationNotifierProvider = NotifierProvider.autoDispose
    .family<DvcPointCalculationNotifier, DvcPointCalculationState, String>(
      DvcPointCalculationNotifier.new,
    );

class DvcPointCalculationNotifier extends Notifier<DvcPointCalculationState> {
  DvcPointCalculationNotifier(this._groupId);

  static const _initialMonthRange = 60;
  static const _rangeIncrement = 60;

  final String _groupId;
  final CalculateDvcPointTableUsecase _calculator =
      const CalculateDvcPointTableUsecase();
  bool _isMutationInProgress = false;

  @override
  DvcPointCalculationState build() {
    final currentMonth = dvcMonthStart(ref.watch(appClockProvider).now());
    Future.microtask(() => unawaited(_loadInitialData()));
    return DvcPointCalculationState(
      visibleStartYearMonth: currentMonth,
      visibleEndYearMonth: dvcAddMonths(currentMonth, _initialMonthRange),
    );
  }

  void showMorePast() {
    state = state.copyWith(
      visibleStartYearMonth: dvcAddMonths(
        state.visibleStartYearMonth,
        -_rangeIncrement,
      ),
    );
    _recalculateIfReady();
  }

  void showMoreFuture() {
    state = state.copyWith(
      visibleEndYearMonth: dvcAddMonths(
        state.visibleEndYearMonth,
        _rangeIncrement,
      ),
    );
    _recalculateIfReady();
  }

  Future<bool> retryGroup() => _retry(_isGroupLoading, _loadGroup);
  Future<bool> retryContracts() => _retry(_areContractsLoading, _loadContracts);
  Future<bool> retryLimitedPoints() =>
      _retry(_areLimitedPointsLoading, _loadLimitedPoints);
  Future<bool> retryPointUsages() =>
      _retry(_arePointUsagesLoading, _loadPointUsages);

  Future<bool> saveContracts(List<DvcPointContractDto> contracts) {
    return _runMutation(
      operationName: 'saveContracts',
      execute: () => ref
          .read(saveDvcPointContractsUsecaseProvider)
          .execute(groupId: _groupId, contracts: contracts),
      reload: _loadContracts,
    );
  }

  Future<bool> saveLimitedPoint(DvcLimitedPointDto limitedPoint) {
    return _runMutation(
      operationName: 'saveLimitedPoint',
      execute: () =>
          ref.read(saveDvcLimitedPointUsecaseProvider).execute(limitedPoint),
      reload: _loadLimitedPoints,
    );
  }

  Future<bool> deleteLimitedPoint(String limitedPointId) {
    return _runMutation(
      operationName: 'deleteLimitedPoint',
      execute: () => ref
          .read(deleteDvcLimitedPointUsecaseProvider)
          .execute(limitedPointId),
      reload: _loadLimitedPoints,
    );
  }

  Future<bool> savePointUsage(DvcPointUsageDto pointUsage) {
    return _runMutation(
      operationName: 'savePointUsage',
      execute: () => ref
          .read(dvcPointUsageMutationCoordinatorProvider)
          .saveDvcPointUsage(pointUsage),
      reload: _loadPointUsages,
    );
  }

  Future<bool> deletePointUsage(String pointUsageId) {
    return _runMutation(
      operationName: 'deletePointUsage',
      execute: () => ref
          .read(dvcPointUsageMutationCoordinatorProvider)
          .deleteDvcPointUsage(pointUsageId),
      reload: _loadPointUsages,
    );
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadGroup(isInitialLoad: true),
      _loadContracts(isInitialLoad: true),
      _loadLimitedPoints(isInitialLoad: true),
      _loadPointUsages(isInitialLoad: true),
    ]);
  }

  Future<bool> _retry(
    bool isLoading,
    Future<void> Function({required bool isInitialLoad}) load,
  ) async {
    if (_isMutationInProgress || isLoading) {
      return false;
    }
    await load(isInitialLoad: false);
    return ref.mounted;
  }

  Future<void> _loadGroup({required bool isInitialLoad}) async {
    state = state.copyWith(
      groupStatus: _loadingStatus(isInitialLoad),
      clearGroupError: true,
    );
    try {
      final group = await ref
          .read(getGroupWithMembersByIdUsecaseProvider)
          .execute(_groupId);
      if (!ref.mounted) return;
      state = state.copyWith(
        group: group,
        clearGroup: group == null,
        groupStatus: DvcPointDataLoadStatus.success,
        clearGroupError: true,
      );
    } catch (e, stack) {
      if (!ref.mounted) return;
      _logLoadError('loadGroup', e, stack);
      state = state.copyWith(
        groupStatus: DvcPointDataLoadStatus.error,
        groupError: e,
      );
    }
  }

  Future<void> _loadContracts({required bool isInitialLoad}) async {
    state = state.copyWith(
      contractsStatus: _loadingStatus(isInitialLoad),
      clearContractsError: true,
    );
    try {
      final contracts = await ref
          .read(getDvcPointContractsUsecaseProvider)
          .execute(_groupId);
      if (!ref.mounted) return;
      state = state.copyWith(
        contracts: contracts,
        contractsStatus: DvcPointDataLoadStatus.success,
        clearContractsError: true,
      );
      _recalculateIfReady();
    } catch (e, stack) {
      if (!ref.mounted) return;
      _logLoadError('loadContracts', e, stack);
      state = state.copyWith(
        contractsStatus: DvcPointDataLoadStatus.error,
        contractsError: e,
      );
    }
  }

  Future<void> _loadLimitedPoints({required bool isInitialLoad}) async {
    state = state.copyWith(
      limitedPointsStatus: _loadingStatus(isInitialLoad),
      clearLimitedPointsError: true,
    );
    try {
      final limitedPoints = await ref
          .read(getDvcLimitedPointsUsecaseProvider)
          .execute(_groupId);
      if (!ref.mounted) return;
      state = state.copyWith(
        limitedPoints: limitedPoints,
        limitedPointsStatus: DvcPointDataLoadStatus.success,
        clearLimitedPointsError: true,
      );
      _recalculateIfReady();
    } catch (e, stack) {
      if (!ref.mounted) return;
      _logLoadError('loadLimitedPoints', e, stack);
      state = state.copyWith(
        limitedPointsStatus: DvcPointDataLoadStatus.error,
        limitedPointsError: e,
      );
    }
  }

  Future<void> _loadPointUsages({required bool isInitialLoad}) async {
    state = state.copyWith(
      pointUsagesStatus: _loadingStatus(isInitialLoad),
      clearPointUsagesError: true,
    );
    try {
      final pointUsages = await ref
          .read(getDvcPointUsagesUsecaseProvider)
          .execute(_groupId);
      if (!ref.mounted) return;
      state = state.copyWith(
        pointUsages: pointUsages,
        pointUsagesStatus: DvcPointDataLoadStatus.success,
        clearPointUsagesError: true,
      );
      _recalculateIfReady();
    } catch (e, stack) {
      if (!ref.mounted) return;
      _logLoadError('loadPointUsages', e, stack);
      state = state.copyWith(
        pointUsagesStatus: DvcPointDataLoadStatus.error,
        pointUsagesError: e,
      );
    }
  }

  Future<bool> _runMutation({
    required String operationName,
    required Future<void> Function() execute,
    required Future<void> Function({required bool isInitialLoad}) reload,
  }) async {
    if (_isMutationInProgress || _isAnyPointDataLoading) return false;
    _isMutationInProgress = true;
    final keepAliveLink = ref.keepAlive();
    try {
      try {
        await execute();
      } catch (e, stack) {
        if (ref.mounted) {
          logger.e(
            'DvcPointCalculationNotifier.$operationName: ${e.toString()}',
            error: e,
            stackTrace: stack,
          );
        }
        rethrow;
      }
      if (!ref.mounted) return false;
      await reload(isInitialLoad: false);
      return ref.mounted;
    } finally {
      _isMutationInProgress = false;
      keepAliveLink.close();
    }
  }

  void _recalculateIfReady() {
    final allPointDataLoaded =
        state.contractsStatus == DvcPointDataLoadStatus.success &&
        state.limitedPointsStatus == DvcPointDataLoadStatus.success &&
        state.pointUsagesStatus == DvcPointDataLoadStatus.success;
    if (state.calculationResult != null || allPointDataLoaded) _recalculate();
  }

  void _recalculate() {
    state = state.copyWith(
      calculationResult: _calculator.execute(
        contracts: state.contracts,
        limitedPoints: state.limitedPoints,
        pointUsages: state.pointUsages,
        startYearMonth: state.visibleStartYearMonth,
        endYearMonth: state.visibleEndYearMonth,
      ),
    );
  }

  void _logLoadError(String operationName, Object error, StackTrace stack) {
    logger.e(
      'DvcPointCalculationNotifier.$operationName: ${error.toString()}',
      error: error,
      stackTrace: stack,
    );
  }

  DvcPointDataLoadStatus _loadingStatus(bool isInitialLoad) => isInitialLoad
      ? DvcPointDataLoadStatus.initialLoading
      : DvcPointDataLoadStatus.refreshing;

  bool get _isGroupLoading => _isLoading(state.groupStatus);
  bool get _areContractsLoading => _isLoading(state.contractsStatus);
  bool get _areLimitedPointsLoading => _isLoading(state.limitedPointsStatus);
  bool get _arePointUsagesLoading => _isLoading(state.pointUsagesStatus);
  bool get _isAnyPointDataLoading =>
      _areContractsLoading ||
      _areLimitedPointsLoading ||
      _arePointUsagesLoading;

  bool _isLoading(DvcPointDataLoadStatus status) =>
      status == DvcPointDataLoadStatus.initialLoading ||
      status == DvcPointDataLoadStatus.refreshing;
}
