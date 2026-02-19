import 'dart:math';

import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';

enum DvcPointSourceType { contract, limited }

class DvcPointAvailableBreakdownDto {
  const DvcPointAvailableBreakdownDto({
    required this.sourceId,
    required this.label,
    required this.point,
    required this.sourceType,
  });

  final String sourceId;
  final String label;
  final int point;
  final DvcPointSourceType sourceType;
}

class DvcPointUsageDetailDto {
  const DvcPointUsageDetailDto({
    required this.id,
    required this.point,
    this.memo,
  });

  final String id;
  final int point;
  final String? memo;
}

class DvcPointMonthlySummaryDto {
  const DvcPointMonthlySummaryDto({
    required this.yearMonth,
    required this.availablePoint,
    required this.usedPoint,
    required this.availableBreakdowns,
    required this.usageDetails,
  });

  final DateTime yearMonth;
  final int availablePoint;
  final int usedPoint;
  final List<DvcPointAvailableBreakdownDto> availableBreakdowns;
  final List<DvcPointUsageDetailDto> usageDetails;
}

class CalculateDvcPointTableUsecase {
  List<DvcPointMonthlySummaryDto> execute({
    required List<DvcPointContractDto> contracts,
    required List<DvcPointUsageDto> usages,
    required List<DvcLimitedPointDto> limitedPoints,
    required List<DateTime> targetMonths,
  }) {
    if (targetMonths.isEmpty) {
      return [];
    }

    final months = _normalizeAndSortTargetMonths(targetMonths);
    final buckets = <_PointBucket>[
      ..._buildContractBuckets(contracts),
      ..._buildLimitedPointBuckets(limitedPoints),
    ];

    final sortedUsages = List<DvcPointUsageDto>.from(usages)
      ..sort((a, b) {
        final monthCompare = _compareMonth(
          _startOfMonth(a.usageYearMonth),
          _startOfMonth(b.usageYearMonth),
        );
        if (monthCompare != 0) {
          return monthCompare;
        }
        return a.id.compareTo(b.id);
      });

    final usagesByMonth = _groupUsagesByMonth(sortedUsages);

    var consumedUsageIndex = 0;
    final summaries = <DvcPointMonthlySummaryDto>[];
    for (final month in months) {
      while (consumedUsageIndex < sortedUsages.length) {
        final usage = sortedUsages[consumedUsageIndex];
        final usageMonth = _startOfMonth(usage.usageYearMonth);
        if (_compareMonth(usageMonth, month) >= 0) {
          break;
        }
        _consumeUsageFromBuckets(usage, buckets);
        consumedUsageIndex++;
      }

      final availableBreakdowns = _buildAvailableBreakdowns(month, buckets);
      final availablePoint = availableBreakdowns.fold<int>(
        0,
        (sum, item) => sum + item.point,
      );

      final monthlyUsages =
          usagesByMonth[_monthKey(month)] ?? <DvcPointUsageDto>[];
      final usageDetails = monthlyUsages
          .map(
            (usage) => DvcPointUsageDetailDto(
              id: usage.id,
              point: usage.usedPoint,
              memo: usage.memo,
            ),
          )
          .toList(growable: false);
      final usedPoint = usageDetails.fold<int>(
        0,
        (sum, item) => sum + item.point,
      );

      summaries.add(
        DvcPointMonthlySummaryDto(
          yearMonth: month,
          availablePoint: availablePoint,
          usedPoint: usedPoint,
          availableBreakdowns: availableBreakdowns,
          usageDetails: usageDetails,
        ),
      );
    }

    return summaries;
  }

  List<DateTime> _normalizeAndSortTargetMonths(List<DateTime> targetMonths) {
    final monthMap = <String, DateTime>{};
    for (final month in targetMonths) {
      final normalized = _startOfMonth(month);
      monthMap[_monthKey(normalized)] = normalized;
    }

    final result = monthMap.values.toList()..sort(_compareMonth);
    return result;
  }

  Map<String, List<DvcPointUsageDto>> _groupUsagesByMonth(
    List<DvcPointUsageDto> sortedUsages,
  ) {
    final result = <String, List<DvcPointUsageDto>>{};
    for (final usage in sortedUsages) {
      final key = _monthKey(_startOfMonth(usage.usageYearMonth));
      final items = result.putIfAbsent(key, () => <DvcPointUsageDto>[]);
      items.add(usage);
    }
    return result;
  }

  void _consumeUsageFromBuckets(
    DvcPointUsageDto usage,
    List<_PointBucket> buckets,
  ) {
    var rest = usage.usedPoint;
    if (rest <= 0) {
      return;
    }

    final usageMonth = _startOfMonth(usage.usageYearMonth);
    final candidates =
        buckets
            .where(
              (bucket) =>
                  bucket.remainingPoint > 0 &&
                  _isInMonthRange(
                    usageMonth,
                    bucket.startYearMonth,
                    bucket.endYearMonth,
                  ),
            )
            .toList()
          ..sort((a, b) {
            final endCompare = _compareMonth(a.endYearMonth, b.endYearMonth);
            if (endCompare != 0) {
              return endCompare;
            }
            final startCompare = _compareMonth(
              a.startYearMonth,
              b.startYearMonth,
            );
            if (startCompare != 0) {
              return startCompare;
            }
            return a.id.compareTo(b.id);
          });

    for (final bucket in candidates) {
      if (rest <= 0) {
        break;
      }
      final consumedPoint = min(rest, bucket.remainingPoint);
      bucket.remainingPoint -= consumedPoint;
      rest -= consumedPoint;
    }
  }

  List<DvcPointAvailableBreakdownDto> _buildAvailableBreakdowns(
    DateTime month,
    List<_PointBucket> buckets,
  ) {
    final grouped = <String, _BreakdownAccumulator>{};

    for (final bucket in buckets) {
      if (bucket.remainingPoint <= 0 ||
          !_isInMonthRange(month, bucket.startYearMonth, bucket.endYearMonth)) {
        continue;
      }

      final accumulator = grouped.putIfAbsent(
        bucket.sourceId,
        () => _BreakdownAccumulator(
          sourceId: bucket.sourceId,
          label: bucket.label,
          sourceType: bucket.sourceType,
        ),
      );
      accumulator.point += bucket.remainingPoint;
    }

    final breakdowns =
        grouped.values
            .map(
              (value) => DvcPointAvailableBreakdownDto(
                sourceId: value.sourceId,
                label: value.label,
                point: value.point,
                sourceType: value.sourceType,
              ),
            )
            .toList()
          ..sort((a, b) {
            final typeCompare = a.sourceType.index.compareTo(
              b.sourceType.index,
            );
            if (typeCompare != 0) {
              return typeCompare;
            }
            return a.label.compareTo(b.label);
          });

    return breakdowns;
  }

  List<_PointBucket> _buildContractBuckets(
    List<DvcPointContractDto> contracts,
  ) {
    final buckets = <_PointBucket>[];

    for (final contract in contracts) {
      final annualPoint = contract.annualPoint;
      if (annualPoint <= 0) {
        continue;
      }

      final contractStart = _startOfMonth(contract.contractStartYearMonth);
      final contractEnd = _startOfMonth(contract.contractEndYearMonth);
      if (_compareMonth(contractStart, contractEnd) > 0) {
        continue;
      }

      if (contract.useYearStartMonth < 1 || contract.useYearStartMonth > 12) {
        continue;
      }

      var grantMonth = DateTime(contractStart.year, contract.useYearStartMonth);
      if (_compareMonth(grantMonth, contractStart) < 0) {
        grantMonth = _addMonths(grantMonth, 12);
      }

      while (_compareMonth(grantMonth, contractEnd) <= 0) {
        final bucketStart = _addMonths(grantMonth, -12);
        final bucketEnd = _addMonths(grantMonth, 11);

        buckets.add(
          _PointBucket(
            id: '${contract.id}-${_monthKey(grantMonth)}',
            sourceId: contract.id,
            label: contract.contractName,
            sourceType: DvcPointSourceType.contract,
            startYearMonth: bucketStart,
            endYearMonth: bucketEnd,
            remainingPoint: annualPoint,
          ),
        );

        grantMonth = _addMonths(grantMonth, 12);
      }
    }

    return buckets;
  }

  List<_PointBucket> _buildLimitedPointBuckets(
    List<DvcLimitedPointDto> limitedPoints,
  ) {
    final buckets = <_PointBucket>[];

    for (final limitedPoint in limitedPoints) {
      if (limitedPoint.point <= 0) {
        continue;
      }

      final startYearMonth = _startOfMonth(limitedPoint.startYearMonth);
      final endYearMonth = _startOfMonth(limitedPoint.endYearMonth);
      if (_compareMonth(startYearMonth, endYearMonth) > 0) {
        continue;
      }

      buckets.add(
        _PointBucket(
          id: limitedPoint.id,
          sourceId: limitedPoint.id,
          label: '期間限定',
          sourceType: DvcPointSourceType.limited,
          startYearMonth: startYearMonth,
          endYearMonth: endYearMonth,
          remainingPoint: limitedPoint.point,
        ),
      );
    }

    return buckets;
  }

  bool _isInMonthRange(
    DateTime month,
    DateTime startYearMonth,
    DateTime endYearMonth,
  ) {
    final normalized = _startOfMonth(month);
    return _compareMonth(normalized, startYearMonth) >= 0 &&
        _compareMonth(normalized, endYearMonth) <= 0;
  }

  int _compareMonth(DateTime a, DateTime b) {
    if (a.year != b.year) {
      return a.year.compareTo(b.year);
    }
    return a.month.compareTo(b.month);
  }

  DateTime _startOfMonth(DateTime value) {
    return DateTime(value.year, value.month);
  }

  DateTime _addMonths(DateTime value, int months) {
    final totalMonths = value.year * 12 + value.month - 1 + months;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    return DateTime(year, month);
  }

  String _monthKey(DateTime value) {
    final normalized = _startOfMonth(value);
    final month = normalized.month.toString().padLeft(2, '0');
    return '${normalized.year}-$month';
  }
}

class _BreakdownAccumulator {
  _BreakdownAccumulator({
    required this.sourceId,
    required this.label,
    required this.sourceType,
  });

  final String sourceId;
  final String label;
  final DvcPointSourceType sourceType;
  int point = 0;
}

class _PointBucket {
  _PointBucket({
    required this.id,
    required this.sourceId,
    required this.label,
    required this.sourceType,
    required this.startYearMonth,
    required this.endYearMonth,
    required this.remainingPoint,
  });

  final String id;
  final String sourceId;
  final String label;
  final DvcPointSourceType sourceType;
  final DateTime startYearMonth;
  final DateTime endYearMonth;
  int remainingPoint;
}
