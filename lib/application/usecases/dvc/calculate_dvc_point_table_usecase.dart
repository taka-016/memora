import 'dart:math';

import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';

enum DvcPointSourceType { contract, limited }

class DvcAvailablePointBreakdown {
  const DvcAvailablePointBreakdown({
    required this.sourceType,
    required this.sourceName,
    required this.remainingPoint,
    required this.availableFrom,
    required this.expireAt,
    this.memo,
  });

  final DvcPointSourceType sourceType;
  final String sourceName;
  final int remainingPoint;
  final DateTime availableFrom;
  final DateTime expireAt;
  final String? memo;
}

class DvcMonthlyPointSummary {
  const DvcMonthlyPointSummary({
    required this.yearMonth,
    required this.availablePoint,
    required this.usedPoint,
    required this.availableBreakdowns,
    required this.usageDetails,
  });

  final DateTime yearMonth;
  final int availablePoint;
  final int usedPoint;
  final List<DvcAvailablePointBreakdown> availableBreakdowns;
  final List<DvcPointUsageDto> usageDetails;
}

class DvcPointTableCalculationResult {
  const DvcPointTableCalculationResult({required this.monthlySummaries});

  final List<DvcMonthlyPointSummary> monthlySummaries;
}

class CalculateDvcPointTableUsecase {
  const CalculateDvcPointTableUsecase();

  DvcPointTableCalculationResult execute({
    required List<DvcPointContractDto> contracts,
    required List<DvcLimitedPointDto> limitedPoints,
    required List<DvcPointUsageDto> pointUsages,
    required DateTime startYearMonth,
    required DateTime endYearMonth,
  }) {
    final normalizedStart = _monthStart(startYearMonth);
    final normalizedEnd = _monthStart(endYearMonth);
    if (normalizedEnd.isBefore(normalizedStart)) {
      return const DvcPointTableCalculationResult(monthlySummaries: []);
    }

    final buckets = <_PointBucket>[
      ...contracts.expand(_buildContractBuckets),
      ...limitedPoints.map(_buildLimitedBucket),
    ];

    final usageList = pointUsages.toList()
      ..sort(
        (a, b) => _monthStart(
          a.usageYearMonth,
        ).compareTo(_monthStart(b.usageYearMonth)),
      );

    final simulationStart = _resolveSimulationStart(
      normalizedStart: normalizedStart,
      buckets: buckets,
      usageList: usageList,
    );

    final usagesByMonth = <String, List<DvcPointUsageDto>>{};
    for (final usage in usageList) {
      final month = _monthStart(usage.usageYearMonth);
      final key = _monthKey(month);
      usagesByMonth[key] = [...?usagesByMonth[key], usage];
    }

    final workingBuckets = buckets.map((bucket) => bucket.copy()).toList();
    final summaries = <DvcMonthlyPointSummary>[];

    for (
      var month = simulationStart;
      !month.isAfter(normalizedEnd);
      month = _addMonths(month, 1)
    ) {
      final monthUsages = usagesByMonth[_monthKey(month)] ?? const [];
      final activeBuckets = _activeBuckets(workingBuckets, month);

      if (!month.isBefore(normalizedStart)) {
        final availableBreakdowns = activeBuckets
            .map(
              (bucket) => DvcAvailablePointBreakdown(
                sourceType: bucket.sourceType,
                sourceName: bucket.sourceName,
                remainingPoint: bucket.remainingPoint,
                availableFrom: bucket.availableFrom,
                expireAt: _addMonths(bucket.expireExclusive, -1),
                memo: bucket.memo,
              ),
            )
            .toList();

        final availablePoint = availableBreakdowns.fold<int>(
          0,
          (sum, breakdown) => sum + breakdown.remainingPoint,
        );
        final usedPoint = monthUsages.fold<int>(
          0,
          (sum, usage) => sum + usage.usedPoint,
        );

        summaries.add(
          DvcMonthlyPointSummary(
            yearMonth: month,
            availablePoint: availablePoint,
            usedPoint: usedPoint,
            availableBreakdowns: availableBreakdowns,
            usageDetails: monthUsages,
          ),
        );
      }

      _consumeByUsages(activeBuckets: activeBuckets, usages: monthUsages);
    }

    return DvcPointTableCalculationResult(monthlySummaries: summaries);
  }

  List<_PointBucket> _buildContractBuckets(DvcPointContractDto contract) {
    if (contract.annualPoint <= 0) {
      return const [];
    }
    if (contract.useYearStartMonth < DateTime.january ||
        contract.useYearStartMonth > DateTime.december) {
      return const [];
    }

    final contractStart = _monthStart(contract.contractStartYearMonth);
    final contractEnd = _monthStart(contract.contractEndYearMonth);
    if (contractEnd.isBefore(contractStart)) {
      return const [];
    }

    var grantMonth = DateTime(contractStart.year, contract.useYearStartMonth);
    if (grantMonth.isBefore(contractStart)) {
      grantMonth = DateTime(grantMonth.year + 1, grantMonth.month);
    }

    final buckets = <_PointBucket>[];
    while (!grantMonth.isAfter(contractEnd)) {
      buckets.add(
        _PointBucket(
          sourceType: DvcPointSourceType.contract,
          sourceName: contract.contractName,
          availableFrom: DateTime(grantMonth.year - 1, grantMonth.month),
          expireExclusive: DateTime(grantMonth.year + 1, grantMonth.month),
          totalPoint: contract.annualPoint,
          remainingPoint: contract.annualPoint,
        ),
      );
      grantMonth = DateTime(grantMonth.year + 1, grantMonth.month);
    }

    return buckets;
  }

  _PointBucket _buildLimitedBucket(DvcLimitedPointDto limitedPoint) {
    final start = _monthStart(limitedPoint.startYearMonth);
    final end = _monthStart(limitedPoint.endYearMonth);
    return _PointBucket(
      sourceType: DvcPointSourceType.limited,
      sourceName: '期間限定ポイント',
      availableFrom: start,
      expireExclusive: _addMonths(end, 1),
      totalPoint: max(0, limitedPoint.point),
      remainingPoint: max(0, limitedPoint.point),
      memo: limitedPoint.memo,
    );
  }

  DateTime _resolveSimulationStart({
    required DateTime normalizedStart,
    required List<_PointBucket> buckets,
    required List<DvcPointUsageDto> usageList,
  }) {
    var result = normalizedStart;
    for (final bucket in buckets) {
      if (bucket.availableFrom.isBefore(result)) {
        result = bucket.availableFrom;
      }
    }
    for (final usage in usageList) {
      final usageMonth = _monthStart(usage.usageYearMonth);
      if (usageMonth.isBefore(result)) {
        result = usageMonth;
      }
    }
    return result;
  }

  List<_PointBucket> _activeBuckets(
    List<_PointBucket> buckets,
    DateTime month,
  ) {
    final active =
        buckets
            .where(
              (bucket) =>
                  bucket.remainingPoint > 0 &&
                  !month.isBefore(bucket.availableFrom) &&
                  month.isBefore(bucket.expireExclusive),
            )
            .toList()
          ..sort((a, b) => a.expireExclusive.compareTo(b.expireExclusive));
    return active;
  }

  void _consumeByUsages({
    required List<_PointBucket> activeBuckets,
    required List<DvcPointUsageDto> usages,
  }) {
    for (final usage in usages) {
      var remainToConsume = usage.usedPoint;
      for (final bucket in activeBuckets) {
        if (remainToConsume <= 0) {
          break;
        }
        final consumable = min(bucket.remainingPoint, remainToConsume);
        bucket.remainingPoint -= consumable;
        remainToConsume -= consumable;
      }
    }
  }

  DateTime _monthStart(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month);

  DateTime _addMonths(DateTime dateTime, int months) {
    return DateTime(dateTime.year, dateTime.month + months);
  }

  String _monthKey(DateTime yearMonth) =>
      '${yearMonth.year}-${yearMonth.month}';
}

class _PointBucket {
  _PointBucket({
    required this.sourceType,
    required this.sourceName,
    required this.availableFrom,
    required this.expireExclusive,
    required this.totalPoint,
    required this.remainingPoint,
    this.memo,
  });

  final DvcPointSourceType sourceType;
  final String sourceName;
  final DateTime availableFrom;
  final DateTime expireExclusive;
  final int totalPoint;
  int remainingPoint;
  final String? memo;

  _PointBucket copy() {
    return _PointBucket(
      sourceType: sourceType,
      sourceName: sourceName,
      availableFrom: availableFrom,
      expireExclusive: expireExclusive,
      totalPoint: totalPoint,
      remainingPoint: remainingPoint,
      memo: memo,
    );
  }
}
