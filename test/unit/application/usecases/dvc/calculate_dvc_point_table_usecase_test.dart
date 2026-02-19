import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/usecases/dvc/calculate_dvc_point_table_usecase.dart';

void main() {
  group('CalculateDvcPointTableUsecase', () {
    late CalculateDvcPointTableUsecase usecase;

    setUp(() {
      usecase = const CalculateDvcPointTableUsecase();
    });

    test('ユースイヤー基準で付与ポイントの有効期限を判定できる', () {
      final contracts = [
        DvcPointContractDto(
          id: 'c1',
          groupId: 'g1',
          contractName: '契約A',
          contractStartYearMonth: DateTime(2025, 10),
          contractEndYearMonth: DateTime(2025, 10),
          useYearStartMonth: 10,
          annualPoint: 100,
        ),
      ];

      final result = usecase.execute(
        contracts: contracts,
        limitedPoints: const [],
        pointUsages: const [],
        startYearMonth: DateTime(2024, 10),
        endYearMonth: DateTime(2026, 10),
      );

      expect(
        _summaryAt(result.monthlySummaries, DateTime(2024, 10)).availablePoint,
        100,
      );
      expect(
        _summaryAt(result.monthlySummaries, DateTime(2026, 9)).availablePoint,
        100,
      );
      expect(
        _summaryAt(result.monthlySummaries, DateTime(2026, 10)).availablePoint,
        0,
      );
    });

    test('契約ごとに異なるユースイヤーを考慮して合算できる', () {
      final contracts = [
        DvcPointContractDto(
          id: 'c1',
          groupId: 'g1',
          contractName: '契約A',
          contractStartYearMonth: DateTime(2025, 10),
          contractEndYearMonth: DateTime(2025, 10),
          useYearStartMonth: 10,
          annualPoint: 100,
        ),
        DvcPointContractDto(
          id: 'c2',
          groupId: 'g1',
          contractName: '契約B',
          contractStartYearMonth: DateTime(2025, 4),
          contractEndYearMonth: DateTime(2025, 4),
          useYearStartMonth: 4,
          annualPoint: 50,
        ),
      ];

      final result = usecase.execute(
        contracts: contracts,
        limitedPoints: const [],
        pointUsages: const [],
        startYearMonth: DateTime(2025, 3),
        endYearMonth: DateTime(2026, 4),
      );

      expect(
        _summaryAt(result.monthlySummaries, DateTime(2025, 3)).availablePoint,
        150,
      );
      expect(
        _summaryAt(result.monthlySummaries, DateTime(2025, 10)).availablePoint,
        150,
      );
      expect(
        _summaryAt(result.monthlySummaries, DateTime(2026, 4)).availablePoint,
        100,
      );
    });

    test('期間限定ポイントを期間内のみ利用可能ポイントへ加算できる', () {
      final contracts = [
        DvcPointContractDto(
          id: 'c1',
          groupId: 'g1',
          contractName: '契約A',
          contractStartYearMonth: DateTime(2025, 10),
          contractEndYearMonth: DateTime(2025, 10),
          useYearStartMonth: 10,
          annualPoint: 100,
        ),
      ];
      final limitedPoints = [
        DvcLimitedPointDto(
          id: 'l1',
          groupId: 'g1',
          startYearMonth: DateTime(2025, 7),
          endYearMonth: DateTime(2025, 12),
          point: 30,
          memo: '期間限定',
        ),
      ];

      final result = usecase.execute(
        contracts: contracts,
        limitedPoints: limitedPoints,
        pointUsages: const [],
        startYearMonth: DateTime(2025, 6),
        endYearMonth: DateTime(2026, 1),
      );

      expect(
        _summaryAt(result.monthlySummaries, DateTime(2025, 6)).availablePoint,
        100,
      );
      expect(
        _summaryAt(result.monthlySummaries, DateTime(2025, 10)).availablePoint,
        130,
      );
      expect(
        _summaryAt(result.monthlySummaries, DateTime(2026, 1)).availablePoint,
        100,
      );
    });

    test('利用登録時は有効期限が早いポイントから消化される', () {
      final contracts = [
        DvcPointContractDto(
          id: 'c1',
          groupId: 'g1',
          contractName: '契約A',
          contractStartYearMonth: DateTime(2024, 10),
          contractEndYearMonth: DateTime(2024, 10),
          useYearStartMonth: 10,
          annualPoint: 100,
        ),
        DvcPointContractDto(
          id: 'c2',
          groupId: 'g1',
          contractName: '契約B',
          contractStartYearMonth: DateTime(2025, 4),
          contractEndYearMonth: DateTime(2025, 4),
          useYearStartMonth: 4,
          annualPoint: 100,
        ),
      ];
      final usages = [
        DvcPointUsageDto(
          id: 'u1',
          groupId: 'g1',
          usageYearMonth: DateTime(2025, 5),
          usedPoint: 120,
          memo: '利用',
        ),
      ];

      final result = usecase.execute(
        contracts: contracts,
        limitedPoints: const [],
        pointUsages: usages,
        startYearMonth: DateTime(2025, 5),
        endYearMonth: DateTime(2025, 6),
      );

      expect(
        _summaryAt(result.monthlySummaries, DateTime(2025, 5)).availablePoint,
        200,
      );
      expect(
        _summaryAt(result.monthlySummaries, DateTime(2025, 5)).usedPoint,
        120,
      );
      expect(
        _summaryAt(result.monthlySummaries, DateTime(2025, 6)).availablePoint,
        80,
      );
    });

    test('当月の利用登録は当月の利用可能ポイント表示に影響しない', () {
      final contracts = [
        DvcPointContractDto(
          id: 'c1',
          groupId: 'g1',
          contractName: '契約A',
          contractStartYearMonth: DateTime(2025, 10),
          contractEndYearMonth: DateTime(2025, 10),
          useYearStartMonth: 10,
          annualPoint: 100,
        ),
      ];
      final usages = [
        DvcPointUsageDto(
          id: 'u1',
          groupId: 'g1',
          usageYearMonth: DateTime(2025, 10),
          usedPoint: 40,
          memo: '利用',
        ),
      ];

      final result = usecase.execute(
        contracts: contracts,
        limitedPoints: const [],
        pointUsages: usages,
        startYearMonth: DateTime(2025, 10),
        endYearMonth: DateTime(2025, 11),
      );

      expect(
        _summaryAt(result.monthlySummaries, DateTime(2025, 10)).availablePoint,
        100,
      );
      expect(
        _summaryAt(result.monthlySummaries, DateTime(2025, 10)).usedPoint,
        40,
      );
      expect(
        _summaryAt(result.monthlySummaries, DateTime(2025, 11)).availablePoint,
        60,
      );
    });
  });
}

DvcMonthlyPointSummary _summaryAt(
  List<DvcMonthlyPointSummary> summaries,
  DateTime target,
) {
  return summaries.firstWhere(
    (summary) =>
        summary.yearMonth.year == target.year &&
        summary.yearMonth.month == target.month,
  );
}
