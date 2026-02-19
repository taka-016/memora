import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/queries/dvc/dvc_limited_point_query_service.dart';
import 'package:memora/application/queries/dvc/dvc_point_contract_query_service.dart';
import 'package:memora/application/queries/dvc/dvc_point_usage_query_service.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
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
    late GroupDto group;
    late _FakeDvcPointContractQueryService contractQueryService;
    late _FakeDvcLimitedPointQueryService limitedQueryService;
    late _FakeDvcPointUsageQueryService usageQueryService;
    late _FakeDvcPointContractRepository contractRepository;
    late _FakeDvcLimitedPointRepository limitedRepository;
    late _FakeDvcPointUsageRepository usageRepository;

    setUp(() {
      group = const GroupDto(
        id: 'g1',
        ownerId: 'o1',
        name: '家族グループ',
        members: [],
      );

      contractQueryService = _FakeDvcPointContractQueryService([
        DvcPointContractDto(
          id: 'c1',
          groupId: 'g1',
          contractName: '契約A',
          contractStartYearMonth: DateTime(2025, 10),
          contractEndYearMonth: DateTime(2025, 10),
          useYearStartMonth: 10,
          annualPoint: 100,
        ),
      ]);
      limitedQueryService = _FakeDvcLimitedPointQueryService(const []);
      usageQueryService = _FakeDvcPointUsageQueryService(const []);

      contractRepository = _FakeDvcPointContractRepository();
      limitedRepository = _FakeDvcLimitedPointRepository();
      usageRepository = _FakeDvcPointUsageRepository();
    });

    Widget createWidget() {
      return ProviderScope(
        overrides: [
          dvcPointContractQueryServiceProvider.overrideWithValue(
            contractQueryService,
          ),
          dvcLimitedPointQueryServiceProvider.overrideWithValue(
            limitedQueryService,
          ),
          dvcPointUsageQueryServiceProvider.overrideWithValue(
            usageQueryService,
          ),
          dvcPointContractRepositoryProvider.overrideWithValue(
            contractRepository,
          ),
          dvcLimitedPointRepositoryProvider.overrideWithValue(
            limitedRepository,
          ),
          dvcPointUsageRepositoryProvider.overrideWithValue(usageRepository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DvcPointCalculationScreen(group: group, onBackPressed: () {}),
          ),
        ),
      );
    }

    testWidgets('ヘッダーとDVCポイント計算テーブルを表示できる', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dvc_point_calculation_screen')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('dvc_back_button')), findsOneWidget);
      expect(find.text('家族グループ'), findsOneWidget);
      expect(
        find.byKey(const Key('dvc_contract_management_button')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('dvc_limited_point_button')), findsOneWidget);
      expect(find.byKey(const Key('dvc_point_table')), findsOneWidget);
      expect(find.text('年月'), findsOneWidget);
      expect(find.text('利用可能\nポイント'), findsOneWidget);
      expect(find.text('利用\nポイント'), findsOneWidget);
    });

    testWidgets('さらに表示で表示月範囲を拡張できる', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final beforeCount = _findMonthCells().evaluate().length;

      await tester.tap(find.byKey(const Key('dvc_show_more_past')));
      await tester.pumpAndSettle();

      final afterCount = _findMonthCells().evaluate().length;
      expect(afterCount, greaterThan(beforeCount));
    });

    testWidgets('初期表示は現在年月から5年後までで、過去年月を含まない', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final current = DateTime.now();
      final currentMonthKey = ValueKey<String>(
        'dvc_month_cell_${current.year}_${current.month}',
      );
      final previousMonth = DateTime(current.year, current.month - 1);
      final previousMonthKey = ValueKey<String>(
        'dvc_month_cell_${previousMonth.year}_${previousMonth.month}',
      );

      expect(find.byKey(currentMonthKey), findsOneWidget);
      expect(find.byKey(previousMonthKey), findsNothing);
    });

    testWidgets('ヘッダ列は横スクロールしても固定表示される', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final before = tester.getTopLeft(find.text('利用可能\nポイント'));
      await tester.drag(
        find.byKey(const Key('dvc_table_horizontal_scroll')),
        const Offset(-1000, 0),
      );
      await tester.pumpAndSettle();
      final after = tester.getTopLeft(find.text('利用可能\nポイント'));

      expect(after.dx, before.dx);
    });

    testWidgets('ヘッダ列の幅は約半分の70pxになっている', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final tableLeft = tester.getTopLeft(
        find.byKey(const Key('dvc_point_table')),
      );
      final scrollLeft = tester.getTopLeft(
        find.byKey(const Key('dvc_table_horizontal_scroll')),
      );

      expect(scrollLeft.dx - tableLeft.dx, 70);
    });

    testWidgets('利用登録の＋ボタンでダイアログを開ける', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(_findAddUsageButtons().first);
      await tester.pumpAndSettle();

      expect(find.text('ポイント利用登録'), findsOneWidget);
      expect(find.text('利用ポイント'), findsOneWidget);
      expect(find.text('メモ'), findsOneWidget);
    });

    testWidgets('契約管理ボタンで契約管理ダイアログを開ける', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dvc_contract_management_button')));
      await tester.pumpAndSettle();

      expect(find.text('契約管理'), findsOneWidget);
      expect(find.byKey(const Key('dvc_contract_add_button')), findsOneWidget);
    });

    testWidgets('期間限定ポイント登録ボタンで登録ダイアログを開ける', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dvc_limited_point_button')));
      await tester.pumpAndSettle();

      expect(find.text('期間限定ポイント登録'), findsOneWidget);
      expect(find.text('開始年月'), findsOneWidget);
      expect(find.text('終了年月'), findsOneWidget);
      expect(find.text('ポイント数'), findsOneWidget);
    });
  });
}

Finder _findMonthCells() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith('dvc_month_cell_');
  });
}

Finder _findAddUsageButtons() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.startsWith('dvc_add_usage_button_');
  });
}

class _FakeDvcPointContractQueryService
    implements DvcPointContractQueryService {
  _FakeDvcPointContractQueryService(this.contracts);

  final List<DvcPointContractDto> contracts;

  @override
  Future<List<DvcPointContractDto>> getDvcPointContractsByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    return contracts.where((contract) => contract.groupId == groupId).toList();
  }
}

class _FakeDvcLimitedPointQueryService implements DvcLimitedPointQueryService {
  _FakeDvcLimitedPointQueryService(this.points);

  final List<DvcLimitedPointDto> points;

  @override
  Future<List<DvcLimitedPointDto>> getDvcLimitedPointsByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    return points.where((point) => point.groupId == groupId).toList();
  }
}

class _FakeDvcPointUsageQueryService implements DvcPointUsageQueryService {
  _FakeDvcPointUsageQueryService(this.usages);

  final List<DvcPointUsageDto> usages;

  @override
  Future<List<DvcPointUsageDto>> getDvcPointUsagesByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    return usages.where((usage) => usage.groupId == groupId).toList();
  }
}

class _FakeDvcPointContractRepository implements DvcPointContractRepository {
  final List<DvcPointContract> savedContracts = [];
  final List<String> deletedContractIds = [];
  final List<String> deletedGroupIds = [];

  @override
  Future<void> deleteDvcPointContract(String contractId) async {
    deletedContractIds.add(contractId);
  }

  @override
  Future<void> deleteDvcPointContractsByGroupId(String groupId) async {
    deletedGroupIds.add(groupId);
  }

  @override
  Future<void> saveDvcPointContract(DvcPointContract contract) async {
    savedContracts.add(contract);
  }
}

class _FakeDvcLimitedPointRepository implements DvcLimitedPointRepository {
  final List<DvcLimitedPoint> savedLimitedPoints = [];
  final List<String> deletedLimitedPointIds = [];
  final List<String> deletedGroupIds = [];

  @override
  Future<void> deleteDvcLimitedPoint(String limitedPointId) async {
    deletedLimitedPointIds.add(limitedPointId);
  }

  @override
  Future<void> deleteDvcLimitedPointsByGroupId(String groupId) async {
    deletedGroupIds.add(groupId);
  }

  @override
  Future<void> saveDvcLimitedPoint(DvcLimitedPoint limitedPoint) async {
    savedLimitedPoints.add(limitedPoint);
  }
}

class _FakeDvcPointUsageRepository implements DvcPointUsageRepository {
  final List<DvcPointUsage> savedUsages = [];
  final List<String> deletedUsageIds = [];
  final List<String> deletedGroupIds = [];

  @override
  Future<void> deleteDvcPointUsage(String pointUsageId) async {
    deletedUsageIds.add(pointUsageId);
  }

  @override
  Future<void> deleteDvcPointUsagesByGroupId(String groupId) async {
    deletedGroupIds.add(groupId);
  }

  @override
  Future<void> saveDvcPointUsage(DvcPointUsage pointUsage) async {
    savedUsages.add(pointUsage);
  }
}
