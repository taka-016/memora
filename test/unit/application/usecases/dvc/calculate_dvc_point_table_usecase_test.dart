import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/usecases/dvc/calculate_dvc_point_table_usecase.dart';

void main() {
  group('CalculateDvcPointTableUsecase', () {
    late CalculateDvcPointTableUsecase usecase;

    setUp(() {
      usecase = CalculateDvcPointTableUsecase();
    });

    test('ユースイヤー基準で付与ポイントの有効期間を計算できる', () {
      // Arrange
      final contracts = [
        DvcPointContractDto(
          id: 'contract-a',
          groupId: 'group-1',
          contractName: '契約A',
          contractStartYearMonth: DateTime(2025, 10),
          contractEndYearMonth: DateTime(2025, 10),
          useYearStartMonth: 10,
          annualPoint: 200,
        ),
      ];

      final targetMonths = [
        DateTime(2024, 9),
        DateTime(2024, 10),
        DateTime(2026, 9),
        DateTime(2026, 10),
      ];

      // Act
      final result = usecase.execute(
        contracts: contracts,
        usages: const [],
        limitedPoints: const [],
        targetMonths: targetMonths,
      );

      // Assert
      expect(result[0].availablePoint, 0);
      expect(result[1].availablePoint, 200);
      expect(result[2].availablePoint, 200);
      expect(result[3].availablePoint, 0);
    });

    test('契約ごとに異なるユースイヤーを合算して利用可能ポイントを計算できる', () {
      // Arrange
      final contracts = [
        DvcPointContractDto(
          id: 'contract-a',
          groupId: 'group-1',
          contractName: '契約A',
          contractStartYearMonth: DateTime(2025, 10),
          contractEndYearMonth: DateTime(2025, 10),
          useYearStartMonth: 10,
          annualPoint: 100,
        ),
        DvcPointContractDto(
          id: 'contract-b',
          groupId: 'group-1',
          contractName: '契約B',
          contractStartYearMonth: DateTime(2025, 4),
          contractEndYearMonth: DateTime(2025, 4),
          useYearStartMonth: 4,
          annualPoint: 200,
        ),
      ];

      // Act
      final result = usecase.execute(
        contracts: contracts,
        usages: const [],
        limitedPoints: const [],
        targetMonths: [DateTime(2025, 10)],
      );

      // Assert
      expect(result.single.availablePoint, 300);
      expect(_toBreakdownMap(result.single.availableBreakdowns), {
        'contract-a': 100,
        'contract-b': 200,
      });
    });

    test('期間限定ポイントを期間内のみ利用可能ポイントに加算できる', () {
      // Arrange
      final limitedPoints = [
        DvcLimitedPointDto(
          id: 'limited-1',
          groupId: 'group-1',
          startYearMonth: DateTime(2025, 7),
          endYearMonth: DateTime(2025, 12),
          point: 30,
          memo: null,
        ),
      ];

      // Act
      final result = usecase.execute(
        contracts: const [],
        usages: const [],
        limitedPoints: limitedPoints,
        targetMonths: [DateTime(2025, 10), DateTime(2026, 1)],
      );

      // Assert
      expect(result[0].availablePoint, 30);
      expect(result[1].availablePoint, 0);
    });

    test('利用月の利用可能ポイントは変えず、翌月以降の利用可能ポイントに反映する', () {
      // Arrange
      final contracts = [
        DvcPointContractDto(
          id: 'contract-a',
          groupId: 'group-1',
          contractName: '契約A',
          contractStartYearMonth: DateTime(2025, 10),
          contractEndYearMonth: DateTime(2025, 10),
          useYearStartMonth: 10,
          annualPoint: 200,
        ),
      ];
      final usages = [
        DvcPointUsageDto(
          id: 'usage-1',
          groupId: 'group-1',
          usageYearMonth: DateTime(2025, 10),
          usedPoint: 50,
          memo: 'テスト利用',
        ),
      ];

      // Act
      final result = usecase.execute(
        contracts: contracts,
        usages: usages,
        limitedPoints: const [],
        targetMonths: [DateTime(2025, 10), DateTime(2025, 11)],
      );

      // Assert
      expect(result[0].availablePoint, 200);
      expect(result[0].usedPoint, 50);
      expect(result[1].availablePoint, 150);
      expect(result[1].usedPoint, 0);
      expect(result[0].usageDetails.single.memo, 'テスト利用');
    });

    test('利用登録時は有効期限が早いポイントから消化する', () {
      // Arrange
      final contracts = [
        DvcPointContractDto(
          id: 'contract-a',
          groupId: 'group-1',
          contractName: '契約A',
          contractStartYearMonth: DateTime(2025, 10),
          contractEndYearMonth: DateTime(2025, 10),
          useYearStartMonth: 10,
          annualPoint: 100,
        ),
        DvcPointContractDto(
          id: 'contract-b',
          groupId: 'group-1',
          contractName: '契約B',
          contractStartYearMonth: DateTime(2025, 4),
          contractEndYearMonth: DateTime(2025, 4),
          useYearStartMonth: 4,
          annualPoint: 100,
        ),
      ];

      final usages = [
        DvcPointUsageDto(
          id: 'usage-1',
          groupId: 'group-1',
          usageYearMonth: DateTime(2025, 10),
          usedPoint: 60,
          memo: null,
        ),
      ];

      // Act
      final result = usecase.execute(
        contracts: contracts,
        usages: usages,
        limitedPoints: const [],
        targetMonths: [DateTime(2025, 11)],
      );

      // Assert
      expect(result.single.availablePoint, 140);
      expect(_toBreakdownMap(result.single.availableBreakdowns), {
        'contract-a': 100,
        'contract-b': 40,
      });
    });

    test('通常ポイントと期間限定ポイントを区別せず、有効期限順で消化する', () {
      // Arrange
      final contracts = [
        DvcPointContractDto(
          id: 'contract-a',
          groupId: 'group-1',
          contractName: '契約A',
          contractStartYearMonth: DateTime(2025, 4),
          contractEndYearMonth: DateTime(2025, 4),
          useYearStartMonth: 4,
          annualPoint: 100,
        ),
      ];
      final limitedPoints = [
        DvcLimitedPointDto(
          id: 'limited-1',
          groupId: 'group-1',
          startYearMonth: DateTime(2025, 1),
          endYearMonth: DateTime(2026, 12),
          point: 50,
          memo: null,
        ),
      ];
      final usages = [
        DvcPointUsageDto(
          id: 'usage-1',
          groupId: 'group-1',
          usageYearMonth: DateTime(2025, 10),
          usedPoint: 40,
          memo: null,
        ),
      ];

      // Act
      final result = usecase.execute(
        contracts: contracts,
        usages: usages,
        limitedPoints: limitedPoints,
        targetMonths: [DateTime(2025, 11)],
      );

      // Assert
      expect(result.single.availablePoint, 110);
      expect(_toBreakdownMap(result.single.availableBreakdowns), {
        'contract-a': 60,
        'limited-1': 50,
      });
    });
  });
}

Map<String, int> _toBreakdownMap(List<DvcPointAvailableBreakdownDto> values) {
  final result = <String, int>{};
  for (final value in values) {
    result[value.sourceId] = value.point;
  }
  return result;
}
