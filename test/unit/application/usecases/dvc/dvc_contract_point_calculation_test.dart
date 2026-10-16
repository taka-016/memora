import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/usecases/dvc/calculate_dvc_point_table_usecase.dart';

void main() {
  const calculator = CalculateDvcPointTableUsecase();
  final month = DateTime(2025, 10);
  DvcPointContractDto contract(String id, int point) => DvcPointContractDto(
    id: id,
    groupId: 'g1',
    contractName: id,
    contractStartYearMonth: month,
    contractEndYearMonth: month,
    useYearStartMonth: 10,
    annualPoint: point,
  );
  DvcPointUsageDto usage(String id, int point) => DvcPointUsageDto(
    id: 'u-$id',
    groupId: 'g1',
    contractId: id,
    usageYearMonth: month,
    usedPoint: point,
  );
  DvcPointTableCalculationResult calculate(
    List<DvcPointUsageDto> usages, {
    List<DvcLimitedPointDto> limited = const [],
  }) => calculator.execute(
    contracts: [contract('a', 60), contract('b', 50)],
    limitedPoints: limited,
    pointUsages: usages,
    startYearMonth: month,
    endYearMonth: DateTime(2025, 11),
  );

  test('契約Aから60pt、契約Bから20pt使い各契約とグループの残高へ反映する', () {
    final result = calculate([usage('a', 60), usage('b', 20)]);
    for (final summary in result.monthlySummaries) {
      expect(summary.availablePoint, 30);
      expect(
        summary.availableBreakdowns
            .firstWhere((v) => v.contractId == 'a')
            .remainingPoint,
        0,
      );
      expect(
        summary.availableBreakdowns
            .firstWhere((v) => v.contractId == 'b')
            .remainingPoint,
        30,
      );
    }
    expect(result.monthlySummaries.first.usedPoint, 80);
    final deleted = calculate([usage('b', 20)]).monthlySummaries.first;
    expect(deleted.availablePoint, 90);
    expect(
      deleted.availableBreakdowns
          .firstWhere((v) => v.contractId == 'a')
          .remainingPoint,
      60,
    );
  });

  test('選択契約の不足を他契約から補填せず翌月も混在させない', () {
    final result = calculate([usage('a', 70)]);
    for (final summary in result.monthlySummaries) {
      expect(summary.availablePoint, 40);
      expect(
        summary.availableBreakdowns
            .firstWhere((v) => v.contractId == 'b')
            .remainingPoint,
        50,
      );
    }
  });

  test('期間限定と通常ポイントを選択契約内の有効期限順に消化する', () {
    final limited = [
      DvcLimitedPointDto(
        id: 'la',
        groupId: 'g1',
        contractId: 'a',
        startYearMonth: month,
        endYearMonth: month,
        point: 10,
      ),
      DvcLimitedPointDto(
        id: 'lb',
        groupId: 'g1',
        contractId: 'b',
        startYearMonth: month,
        endYearMonth: month,
        point: 30,
      ),
    ];
    final result = calculate([usage('a', 20)], limited: limited);
    final summary = result.monthlySummaries.first;
    expect(
      summary.availableBreakdowns
          .firstWhere((v) => v.sourceId == 'la')
          .remainingPoint,
      0,
    );
    expect(
      summary.availableBreakdowns
          .firstWhere((v) => v.sourceId == 'lb')
          .remainingPoint,
      30,
    );
    expect(
      summary.availableBreakdowns
          .firstWhere((v) => v.sourceId == 'a')
          .remainingPoint,
      50,
    );
    expect(summary.availablePoint, 130);
    expect(result.monthlySummaries.last.availablePoint, 100);
  });
}
