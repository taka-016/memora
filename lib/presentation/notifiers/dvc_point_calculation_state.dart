import 'package:equatable/equatable.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/usecases/dvc/calculate_dvc_point_table_usecase.dart';

enum DvcPointDataLoadStatus { initialLoading, refreshing, success, error }

class DvcPointCalculationState extends Equatable {
  const DvcPointCalculationState({
    required this.visibleStartYearMonth,
    required this.visibleEndYearMonth,
    this.group,
    this.contracts = const [],
    this.limitedPoints = const [],
    this.pointUsages = const [],
    this.calculationResult,
    this.groupStatus = DvcPointDataLoadStatus.initialLoading,
    this.contractsStatus = DvcPointDataLoadStatus.initialLoading,
    this.limitedPointsStatus = DvcPointDataLoadStatus.initialLoading,
    this.pointUsagesStatus = DvcPointDataLoadStatus.initialLoading,
    this.groupError,
    this.contractsError,
    this.limitedPointsError,
    this.pointUsagesError,
  });

  final DateTime visibleStartYearMonth;
  final DateTime visibleEndYearMonth;
  final GroupDto? group;
  final List<DvcPointContractDto> contracts;
  final List<DvcLimitedPointDto> limitedPoints;
  final List<DvcPointUsageDto> pointUsages;
  final DvcPointTableCalculationResult? calculationResult;
  final DvcPointDataLoadStatus groupStatus;
  final DvcPointDataLoadStatus contractsStatus;
  final DvcPointDataLoadStatus limitedPointsStatus;
  final DvcPointDataLoadStatus pointUsagesStatus;
  final Object? groupError;
  final Object? contractsError;
  final Object? limitedPointsError;
  final Object? pointUsagesError;

  bool get isInitialLoading =>
      groupStatus == DvcPointDataLoadStatus.initialLoading ||
      contractsStatus == DvcPointDataLoadStatus.initialLoading ||
      limitedPointsStatus == DvcPointDataLoadStatus.initialLoading ||
      pointUsagesStatus == DvcPointDataLoadStatus.initialLoading;

  bool get hasUsableData =>
      calculationResult != null &&
      (groupStatus != DvcPointDataLoadStatus.error || group != null);

  bool get hasLoadError =>
      groupStatus == DvcPointDataLoadStatus.error ||
      contractsStatus == DvcPointDataLoadStatus.error ||
      limitedPointsStatus == DvcPointDataLoadStatus.error ||
      pointUsagesStatus == DvcPointDataLoadStatus.error;

  DvcPointCalculationState copyWith({
    DateTime? visibleStartYearMonth,
    DateTime? visibleEndYearMonth,
    GroupDto? group,
    bool clearGroup = false,
    List<DvcPointContractDto>? contracts,
    List<DvcLimitedPointDto>? limitedPoints,
    List<DvcPointUsageDto>? pointUsages,
    DvcPointTableCalculationResult? calculationResult,
    DvcPointDataLoadStatus? groupStatus,
    DvcPointDataLoadStatus? contractsStatus,
    DvcPointDataLoadStatus? limitedPointsStatus,
    DvcPointDataLoadStatus? pointUsagesStatus,
    Object? groupError,
    bool clearGroupError = false,
    Object? contractsError,
    bool clearContractsError = false,
    Object? limitedPointsError,
    bool clearLimitedPointsError = false,
    Object? pointUsagesError,
    bool clearPointUsagesError = false,
  }) {
    return DvcPointCalculationState(
      visibleStartYearMonth:
          visibleStartYearMonth ?? this.visibleStartYearMonth,
      visibleEndYearMonth: visibleEndYearMonth ?? this.visibleEndYearMonth,
      group: clearGroup ? null : group ?? this.group,
      contracts: contracts ?? this.contracts,
      limitedPoints: limitedPoints ?? this.limitedPoints,
      pointUsages: pointUsages ?? this.pointUsages,
      calculationResult: calculationResult ?? this.calculationResult,
      groupStatus: groupStatus ?? this.groupStatus,
      contractsStatus: contractsStatus ?? this.contractsStatus,
      limitedPointsStatus: limitedPointsStatus ?? this.limitedPointsStatus,
      pointUsagesStatus: pointUsagesStatus ?? this.pointUsagesStatus,
      groupError: clearGroupError ? null : groupError ?? this.groupError,
      contractsError: clearContractsError
          ? null
          : contractsError ?? this.contractsError,
      limitedPointsError: clearLimitedPointsError
          ? null
          : limitedPointsError ?? this.limitedPointsError,
      pointUsagesError: clearPointUsagesError
          ? null
          : pointUsagesError ?? this.pointUsagesError,
    );
  }

  @override
  List<Object?> get props => [
    visibleStartYearMonth,
    visibleEndYearMonth,
    group,
    contracts,
    limitedPoints,
    pointUsages,
    calculationResult,
    groupStatus,
    contractsStatus,
    limitedPointsStatus,
    pointUsagesStatus,
    groupError,
    contractsError,
    limitedPointsError,
    pointUsagesError,
  ];
}
