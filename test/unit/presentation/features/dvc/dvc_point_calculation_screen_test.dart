import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/queries/dvc/dvc_limited_point_query_service.dart';
import 'package:memora/application/queries/dvc/dvc_point_contract_query_service.dart';
import 'package:memora/application/queries/dvc/dvc_point_usage_query_service.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';
import 'package:memora/domain/repositories/dvc/dvc_limited_point_repository.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_contract_repository.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_usage_repository.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/presentation/features/dvc/dvc_point_calculation_screen.dart';

void main() {
  group('DvcPointCalculationScreen', () {
    late GroupDto testGroup;
    late FakeDvcPointContractQueryService contractQueryService;
    late FakeDvcPointUsageQueryService usageQueryService;
    late FakeDvcLimitedPointQueryService limitedQueryService;
    late FakeDvcPointContractRepository contractRepository;
    late FakeDvcPointUsageRepository usageRepository;
    late FakeDvcLimitedPointRepository limitedRepository;

    setUp(() {
      testGroup = const GroupDto(
        id: 'group-1',
        ownerId: 'owner-1',
        name: '家族',
        members: [],
      );
      contractQueryService = FakeDvcPointContractQueryService(
        valuesByGroupId: {
          'group-1': [
            DvcPointContractDto(
              id: 'contract-a',
              groupId: 'group-1',
              contractName: '契約A',
              contractStartYearMonth: DateTime(2025, 10),
              contractEndYearMonth: DateTime(2025, 10),
              useYearStartMonth: 10,
              annualPoint: 200,
            ),
          ],
          'group-2': [
            DvcPointContractDto(
              id: 'contract-other',
              groupId: 'group-2',
              contractName: '別グループ契約',
              contractStartYearMonth: DateTime(2025, 10),
              contractEndYearMonth: DateTime(2025, 10),
              useYearStartMonth: 10,
              annualPoint: 400,
            ),
          ],
        },
      );
      usageQueryService = FakeDvcPointUsageQueryService(
        valuesByGroupId: {
          'group-1': [
            DvcPointUsageDto(
              id: 'usage-1',
              groupId: 'group-1',
              usageYearMonth: DateTime(2025, 10),
              usedPoint: 50,
              memo: 'メモA',
            ),
          ],
        },
      );
      limitedQueryService = FakeDvcLimitedPointQueryService(
        valuesByGroupId: {
          'group-1': [
            DvcLimitedPointDto(
              id: 'limited-1',
              groupId: 'group-1',
              startYearMonth: DateTime(2025, 7),
              endYearMonth: DateTime(2025, 12),
              point: 30,
              memo: 'キャンペーン',
            ),
          ],
        },
      );
      contractRepository = FakeDvcPointContractRepository();
      usageRepository = FakeDvcPointUsageRepository();
      limitedRepository = FakeDvcLimitedPointRepository();
    });

    Widget createWidget() {
      return ProviderScope(
        overrides: [
          dvcPointContractQueryServiceProvider.overrideWithValue(
            contractQueryService,
          ),
          dvcPointUsageQueryServiceProvider.overrideWithValue(
            usageQueryService,
          ),
          dvcLimitedPointQueryServiceProvider.overrideWithValue(
            limitedQueryService,
          ),
          dvcPointContractRepositoryProvider.overrideWithValue(
            contractRepository,
          ),
          dvcPointUsageRepositoryProvider.overrideWithValue(usageRepository),
          dvcLimitedPointRepositoryProvider.overrideWithValue(
            limitedRepository,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DvcPointCalculationScreen(
              group: testGroup,
              onBackPressed: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('選択中グループの契約一覧と月次テーブルを表示する', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.byKey(const Key('dvc_contract_item_contract-a')),
        findsOneWidget,
      );
      expect(find.text('別グループ契約'), findsNothing);
      expect(find.byKey(const Key('dvc_point_table')), findsOneWidget);
      expect(
        find.byKey(const Key('dvc_available_cell_2025-10')),
        findsOneWidget,
      );
      expect(find.text('230'), findsWidgets);
      expect(contractQueryService.calledGroupIds, contains('group-1'));
      expect(contractQueryService.calledGroupIds, isNot(contains('group-2')));
    });

    testWidgets('契約未登録でも契約登録導線を表示する', (tester) async {
      // Arrange
      contractQueryService.valuesByGroupId['group-1'] = [];
      usageQueryService.valuesByGroupId['group-1'] = [];
      limitedQueryService.valuesByGroupId['group-1'] = [];

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('契約が登録されていません。下のフォームから登録してください。'), findsOneWidget);
      expect(find.byKey(const Key('dvc_contract_name_input')), findsOneWidget);
      expect(find.byKey(const Key('dvc_contract_add_button')), findsOneWidget);
    });

    testWidgets('契約登録後に同画面で再読み込みする', (tester) async {
      // Arrange
      contractQueryService.valuesByGroupId['group-1'] = [];
      usageQueryService.valuesByGroupId['group-1'] = [];
      limitedQueryService.valuesByGroupId['group-1'] = [];

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final initialCallCount = contractQueryService.callCount;

      await tester.enterText(
        find.byKey(const Key('dvc_contract_name_input')),
        '新規契約',
      );
      await tester.enterText(
        find.byKey(const Key('dvc_contract_use_year_start_month_input')),
        '10',
      );
      await tester.enterText(
        find.byKey(const Key('dvc_contract_annual_point_input')),
        '220',
      );
      final contractAddButton = find.byKey(
        const Key('dvc_contract_add_button'),
      );
      await tester.ensureVisible(contractAddButton);
      await tester.tap(contractAddButton);
      await tester.pumpAndSettle();

      // Assert
      expect(contractRepository.savedContracts.length, 1);
      expect(contractRepository.savedContracts.single.groupId, 'group-1');
      expect(contractRepository.savedContracts.single.contractName, '新規契約');
      expect(contractRepository.savedContracts.single.useYearStartMonth, 10);
      expect(contractRepository.savedContracts.single.annualPoint, 220);
      expect(contractQueryService.callCount, greaterThan(initialCallCount));
    });

    testWidgets('利用可能ポイント内訳を表示できる', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final availableCell = find.byKey(const Key('dvc_available_cell_2025-10'));
      await tester.ensureVisible(availableCell);
      await tester.tap(availableCell);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('利用可能ポイント内訳'), findsOneWidget);
      expect(find.textContaining('契約A'), findsWidgets);
      expect(find.textContaining('期間限定'), findsWidgets);
    });

    testWidgets('利用登録済みポイント内訳を表示できる', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final usedCell = find.byKey(const Key('dvc_used_cell_2025-10'));
      await tester.ensureVisible(usedCell);
      await tester.tap(usedCell);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('利用登録済みポイント内訳'), findsOneWidget);
      expect(find.textContaining('50pt'), findsOneWidget);
      expect(find.textContaining('メモA'), findsOneWidget);
    });

    testWidgets('利用登録と期間限定ポイント登録ができる', (tester) async {
      // Arrange
      contractQueryService.valuesByGroupId['group-1'] = [];
      usageQueryService.valuesByGroupId['group-1'] = [];
      limitedQueryService.valuesByGroupId['group-1'] = [];

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('dvc_usage_month_input')),
        '2025-10',
      );
      await tester.enterText(
        find.byKey(const Key('dvc_usage_point_input')),
        '40',
      );
      await tester.enterText(
        find.byKey(const Key('dvc_usage_memo_input')),
        '宿泊利用',
      );
      final usageAddButton = find.byKey(const Key('dvc_usage_add_button'));
      await tester.ensureVisible(usageAddButton);
      await tester.tap(usageAddButton);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('dvc_limited_start_month_input')),
        '2025-07',
      );
      await tester.enterText(
        find.byKey(const Key('dvc_limited_end_month_input')),
        '2025-12',
      );
      await tester.enterText(
        find.byKey(const Key('dvc_limited_point_input')),
        '30',
      );
      await tester.enterText(
        find.byKey(const Key('dvc_limited_memo_input')),
        'キャンペーン',
      );
      final limitedAddButton = find.byKey(const Key('dvc_limited_add_button'));
      await tester.ensureVisible(limitedAddButton);
      await tester.tap(limitedAddButton);
      await tester.pumpAndSettle();

      // Assert
      expect(usageRepository.savedUsages.length, 1);
      expect(usageRepository.savedUsages.single.groupId, 'group-1');
      expect(usageRepository.savedUsages.single.usedPoint, 40);
      expect(usageRepository.savedUsages.single.memo, '宿泊利用');

      expect(limitedRepository.savedLimitedPoints.length, 1);
      expect(limitedRepository.savedLimitedPoints.single.groupId, 'group-1');
      expect(limitedRepository.savedLimitedPoints.single.point, 30);
      expect(limitedRepository.savedLimitedPoints.single.memo, 'キャンペーン');
    });
  });
}

class FakeDvcPointContractQueryService implements DvcPointContractQueryService {
  FakeDvcPointContractQueryService({required this.valuesByGroupId});

  final Map<String, List<DvcPointContractDto>> valuesByGroupId;
  final List<String> calledGroupIds = [];
  int callCount = 0;

  @override
  Future<List<DvcPointContractDto>> getDvcPointContractsByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    callCount++;
    calledGroupIds.add(groupId);
    return valuesByGroupId[groupId] ?? [];
  }
}

class FakeDvcPointUsageQueryService implements DvcPointUsageQueryService {
  FakeDvcPointUsageQueryService({required this.valuesByGroupId});

  final Map<String, List<DvcPointUsageDto>> valuesByGroupId;

  @override
  Future<List<DvcPointUsageDto>> getDvcPointUsagesByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    return valuesByGroupId[groupId] ?? [];
  }
}

class FakeDvcLimitedPointQueryService implements DvcLimitedPointQueryService {
  FakeDvcLimitedPointQueryService({required this.valuesByGroupId});

  final Map<String, List<DvcLimitedPointDto>> valuesByGroupId;

  @override
  Future<List<DvcLimitedPointDto>> getDvcLimitedPointsByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    return valuesByGroupId[groupId] ?? [];
  }
}

class FakeDvcPointContractRepository implements DvcPointContractRepository {
  final List<DvcPointContract> savedContracts = [];

  @override
  Future<void> deleteDvcPointContract(String contractId) async {}

  @override
  Future<void> deleteDvcPointContractsByGroupId(String groupId) async {}

  @override
  Future<void> saveDvcPointContract(DvcPointContract contract) async {
    savedContracts.add(contract);
  }
}

class FakeDvcPointUsageRepository implements DvcPointUsageRepository {
  final List<DvcPointUsage> savedUsages = [];

  @override
  Future<void> deleteDvcPointUsage(String pointUsageId) async {}

  @override
  Future<void> deleteDvcPointUsagesByGroupId(String groupId) async {}

  @override
  Future<void> saveDvcPointUsage(DvcPointUsage pointUsage) async {
    savedUsages.add(pointUsage);
  }
}

class FakeDvcLimitedPointRepository implements DvcLimitedPointRepository {
  final List<DvcLimitedPoint> savedLimitedPoints = [];

  @override
  Future<void> deleteDvcLimitedPoint(String limitedPointId) async {}

  @override
  Future<void> deleteDvcLimitedPointsByGroupId(String groupId) async {}

  @override
  Future<void> saveDvcLimitedPoint(DvcLimitedPoint limitedPoint) async {
    savedLimitedPoints.add(limitedPoint);
  }
}
