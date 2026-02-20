import 'dart:async';

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
        findsNothing,
      );
      expect(find.byKey(const Key('dvc_limited_point_button')), findsNothing);
      expect(find.byKey(const Key('dvc_action_menu_button')), findsOneWidget);
      expect(find.byKey(const Key('dvc_point_table')), findsOneWidget);
      expect(find.text('年月'), findsOneWidget);
      expect(find.text('利用可能\nポイント'), findsOneWidget);
      expect(find.text('利用\nポイント'), findsOneWidget);
    });

    testWidgets('左右矢印で表示月範囲を拡張できる', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('さらに\n表示'), findsNothing);
      final pastButton = tester.widget<IconButton>(
        find.byKey(const Key('dvc_show_more_past')),
      );
      final futureButton = tester.widget<IconButton>(
        find.byKey(const Key('dvc_show_more_future')),
      );
      expect((pastButton.icon as Icon).icon, Icons.arrow_left);
      expect((futureButton.icon as Icon).icon, Icons.arrow_right);
      expect(pastButton.iconSize, 28);
      expect(futureButton.iconSize, 28);

      final beforeCount = _findMonthCells().evaluate().length;

      await tester.tap(find.byKey(const Key('dvc_show_more_past')));
      await tester.pumpAndSettle();

      final afterCount = _findMonthCells().evaluate().length;
      expect(afterCount, greaterThan(beforeCount));
    });

    testWidgets('利用可能ポイントと利用ポイントのセルにptを表示しない', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining(' pt'), findsNothing);
    });

    testWidgets('利用可能ポイントがマイナスの場合は赤字太字で表示する', (tester) async {
      final currentMonth = _monthStart(DateTime.now());
      contractQueryService = _FakeDvcPointContractQueryService([
        DvcPointContractDto(
          id: 'c-current',
          groupId: 'g1',
          contractName: '契約A',
          contractStartYearMonth: currentMonth,
          contractEndYearMonth: currentMonth,
          useYearStartMonth: currentMonth.month,
          annualPoint: 100,
        ),
      ]);
      usageQueryService = _FakeDvcPointUsageQueryService([
        DvcPointUsageDto(
          id: 'u-current',
          groupId: 'g1',
          usageYearMonth: currentMonth,
          usedPoint: 110,
          memo: '超過利用',
        ),
      ]);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final negativeAvailablePointTextFinder = find.descendant(
        of: find.byKey(
          ValueKey(
            'dvc_available_cell_${currentMonth.year}_${currentMonth.month}',
          ),
        ),
        matching: find.text('-10'),
      );

      expect(negativeAvailablePointTextFinder, findsOneWidget);

      final negativeAvailablePointText = tester.widget<Text>(
        negativeAvailablePointTextFinder,
      );
      expect(negativeAvailablePointText.style?.color, Colors.red);
      expect(negativeAvailablePointText.style?.fontWeight, FontWeight.bold);
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

    testWidgets('利用ポイント登録後に横スクロール位置を維持したまま再計算できる', (tester) async {
      final currentMonth = _monthStart(DateTime.now());
      final usages = <DvcPointUsageDto>[];
      final secondLoadCompleter = Completer<void>();
      usageQueryService = _FakeDvcPointUsageQueryService(
        usages,
        onBeforeReturn: (callCount) async {
          if (callCount == 2) {
            await secondLoadCompleter.future;
          }
        },
      );
      usageRepository = _FakeDvcPointUsageRepository(
        onSave: (pointUsage) {
          usages.add(
            DvcPointUsageDto(
              id: 'u${usages.length + 1}',
              groupId: pointUsage.groupId,
              usageYearMonth: pointUsage.usageYearMonth,
              usedPoint: pointUsage.usedPoint,
              memo: pointUsage.memo,
            ),
          );
        },
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const Key('dvc_table_horizontal_scroll')),
        const Offset(-40, 0),
      );
      await tester.pumpAndSettle();

      final offsetBefore = _horizontalScrollOffset(tester);
      expect(offsetBefore, greaterThan(0));

      await tester.tap(
        find.byKey(
          ValueKey(
            'dvc_add_usage_button_${currentMonth.year}_${currentMonth.month}',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('dvc_usage_point_field')),
        '10',
      );
      await tester.tap(find.widgetWithText(TextButton, '登録'));
      await tester.pump();

      expect(find.byKey(const Key('dvc_point_table')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      secondLoadCompleter.complete();
      await tester.pumpAndSettle();

      final usedCell = find.byKey(
        ValueKey('dvc_used_cell_${currentMonth.year}_${currentMonth.month}'),
      );
      expect(
        find.descendant(of: usedCell, matching: find.text('10')),
        findsOneWidget,
      );

      final offsetAfter = _horizontalScrollOffset(tester);
      expect(offsetAfter, closeTo(offsetBefore, 0.1));
    });

    testWidgets('3点メニューで操作メニューを開ける', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dvc_action_menu_button')));
      await tester.pumpAndSettle();

      expect(find.text('契約登録'), findsOneWidget);
      expect(find.text('期間限定ポイント登録'), findsOneWidget);
    });

    testWidgets('3点メニューの契約登録で契約管理ダイアログを開ける', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dvc_action_menu_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('契約登録'));
      await tester.pumpAndSettle();

      expect(find.text('契約管理'), findsOneWidget);
      expect(find.byKey(const Key('dvc_contract_add_button')), findsOneWidget);
    });

    testWidgets('契約管理ダイアログで契約カードを削除して更新できる', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dvc_action_menu_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('契約登録'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('dvc_contract_delete_button_0')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, '更新'));
      await tester.pumpAndSettle();

      expect(contractRepository.deletedGroupIds, contains('g1'));
      expect(contractRepository.savedContracts, isEmpty);
    });

    testWidgets('3点メニューの期間限定ポイント登録で登録ダイアログを開ける', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dvc_action_menu_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('期間限定ポイント登録'));
      await tester.pumpAndSettle();

      expect(find.text('期間限定ポイント登録'), findsOneWidget);
      expect(find.text('開始年月'), findsOneWidget);
      expect(find.text('終了年月'), findsOneWidget);
      expect(find.text('ポイント数'), findsOneWidget);
    });

    testWidgets('利用可能ポイント内訳タイトルは年月で改行して2段表示する', (tester) async {
      final currentMonth = _monthStart(DateTime.now());
      contractQueryService = _FakeDvcPointContractQueryService([
        DvcPointContractDto(
          id: 'c-current',
          groupId: 'g1',
          contractName: '契約A',
          contractStartYearMonth: currentMonth,
          contractEndYearMonth: currentMonth,
          useYearStartMonth: currentMonth.month,
          annualPoint: 100,
        ),
      ]);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          ValueKey(
            'dvc_available_cell_${currentMonth.year}_${currentMonth.month}',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('${_formatYearMonthForTest(currentMonth)}\n利用可能ポイント内訳'),
        findsOneWidget,
      );
    });

    testWidgets('利用ポイント内訳タイトルは年月で改行して2段表示する', (tester) async {
      final currentMonth = _monthStart(DateTime.now());
      usageQueryService = _FakeDvcPointUsageQueryService([
        DvcPointUsageDto(
          id: 'u1',
          groupId: 'g1',
          usageYearMonth: currentMonth,
          usedPoint: 10,
          memo: '利用済み',
        ),
      ]);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await _tapUsageCellBody(tester, currentMonth);
      await tester.pumpAndSettle();

      expect(
        find.text('${_formatYearMonthForTest(currentMonth)}\n利用ポイント内訳'),
        findsOneWidget,
      );
    });

    testWidgets('有効期限内で0ポイントになった利用可能ポイントも0ptで表示する', (tester) async {
      final currentMonth = _monthStart(DateTime.now());
      contractQueryService = _FakeDvcPointContractQueryService([
        DvcPointContractDto(
          id: 'c-current',
          groupId: 'g1',
          contractName: '契約A',
          contractStartYearMonth: currentMonth,
          contractEndYearMonth: currentMonth,
          useYearStartMonth: currentMonth.month,
          annualPoint: 100,
        ),
      ]);
      usageQueryService = _FakeDvcPointUsageQueryService([
        DvcPointUsageDto(
          id: 'u1',
          groupId: 'g1',
          usageYearMonth: DateTime(currentMonth.year, currentMonth.month - 1),
          usedPoint: 100,
          memo: '使い切り',
        ),
      ]);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          ValueKey(
            'dvc_available_cell_${currentMonth.year}_${currentMonth.month}',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('契約A: 0pt'), findsOneWidget);
    });

    testWidgets('利用可能ポイント内訳にユースイヤーと有効期限を表示する', (tester) async {
      final currentMonth = _monthStart(DateTime.now());
      contractQueryService = _FakeDvcPointContractQueryService([
        DvcPointContractDto(
          id: 'c-current',
          groupId: 'g1',
          contractName: '契約A',
          contractStartYearMonth: currentMonth,
          contractEndYearMonth: currentMonth,
          useYearStartMonth: currentMonth.month,
          annualPoint: 100,
        ),
      ]);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          ValueKey(
            'dvc_available_cell_${currentMonth.year}_${currentMonth.month}',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('${currentMonth.year}ユースイヤー'), findsOneWidget);
      expect(find.textContaining('有効期限:'), findsOneWidget);
    });

    testWidgets('利用可能ポイント内訳の期間限定ポイントは削除できる', (tester) async {
      final currentMonth = _monthStart(DateTime.now());
      contractQueryService = _FakeDvcPointContractQueryService(const []);
      limitedQueryService = _FakeDvcLimitedPointQueryService([
        DvcLimitedPointDto(
          id: 'l1',
          groupId: 'g1',
          startYearMonth: currentMonth,
          endYearMonth: currentMonth,
          point: 30,
          memo: '削除対象',
        ),
      ]);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          ValueKey(
            'dvc_available_cell_${currentMonth.year}_${currentMonth.month}',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('dvc_limited_point_delete_button_l1')),
      );
      await tester.pumpAndSettle();

      expect(limitedRepository.deletedLimitedPointIds, contains('l1'));
    });

    testWidgets('利用可能ポイント内訳の有効期限はfrom〜to形式で表示する', (tester) async {
      final currentMonth = _monthStart(DateTime.now());
      contractQueryService = _FakeDvcPointContractQueryService(const []);
      limitedQueryService = _FakeDvcLimitedPointQueryService([
        DvcLimitedPointDto(
          id: 'l1',
          groupId: 'g1',
          startYearMonth: currentMonth,
          endYearMonth: DateTime(currentMonth.year, currentMonth.month + 2),
          point: 30,
          memo: 'メモ',
        ),
      ]);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          ValueKey(
            'dvc_available_cell_${currentMonth.year}_${currentMonth.month}',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final endMonth = DateTime(currentMonth.year, currentMonth.month + 2);
      expect(
        find.text(
          '有効期限: ${_formatYearMonthForTest(currentMonth)}〜${_formatYearMonthForTest(endMonth)}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('期間限定ポイントの内訳はメモを有効期限より先に表示する', (tester) async {
      final currentMonth = _monthStart(DateTime.now());
      contractQueryService = _FakeDvcPointContractQueryService(const []);
      limitedQueryService = _FakeDvcLimitedPointQueryService([
        DvcLimitedPointDto(
          id: 'l1',
          groupId: 'g1',
          startYearMonth: currentMonth,
          endYearMonth: currentMonth,
          point: 30,
          memo: '期間限定メモ',
        ),
      ]);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          ValueKey(
            'dvc_available_cell_${currentMonth.year}_${currentMonth.month}',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tileFinder = find.ancestor(
        of: find.text('期間限定ポイント: 30pt'),
        matching: find.byType(ListTile),
      );
      final subtitleColumnFinder = find.descendant(
        of: tileFinder,
        matching: find.byType(Column),
      );
      final subtitleColumn = tester.widget<Column>(subtitleColumnFinder.first);
      final subtitleTexts = subtitleColumn.children
          .whereType<Text>()
          .map((text) => text.data)
          .whereType<String>()
          .toList();

      expect(subtitleTexts[0], '期間限定メモ');
      expect(
        subtitleTexts[1],
        '有効期限: ${_formatYearMonthForTest(currentMonth)}〜${_formatYearMonthForTest(currentMonth)}',
      );
    });

    testWidgets('利用ポイント内訳から利用登録済ポイントを削除できる', (tester) async {
      final currentMonth = _monthStart(DateTime.now());
      usageQueryService = _FakeDvcPointUsageQueryService([
        DvcPointUsageDto(
          id: 'u1',
          groupId: 'g1',
          usageYearMonth: currentMonth,
          usedPoint: 10,
          memo: '削除対象',
        ),
      ]);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await _tapUsageCellBody(tester, currentMonth);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('dvc_usage_delete_button_u1')),
      );
      await tester.pumpAndSettle();

      expect(usageRepository.deletedUsageIds, contains('u1'));
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

double _horizontalScrollOffset(WidgetTester tester) {
  final scrollable = find.descendant(
    of: find.byKey(const Key('dvc_table_horizontal_scroll')),
    matching: find.byType(Scrollable),
  );
  final state = tester.state<ScrollableState>(scrollable);
  return state.position.pixels;
}

DateTime _monthStart(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month);

String _formatYearMonthForTest(DateTime dateTime) {
  final month = dateTime.month.toString().padLeft(2, '0');
  return '${dateTime.year}-$month';
}

Future<void> _tapUsageCellBody(WidgetTester tester, DateTime month) async {
  final cellFinder = find.byKey(
    ValueKey('dvc_used_cell_${month.year}_${month.month}'),
  );
  final rect = tester.getRect(cellFinder);
  await tester.tapAt(Offset(rect.center.dx, rect.top + 12));
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
  _FakeDvcPointUsageQueryService(this.usages, {this.onBeforeReturn});

  final List<DvcPointUsageDto> usages;
  final Future<void> Function(int callCount)? onBeforeReturn;
  int _callCount = 0;

  @override
  Future<List<DvcPointUsageDto>> getDvcPointUsagesByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    _callCount += 1;
    if (onBeforeReturn != null) {
      await onBeforeReturn!(_callCount);
    }
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
  _FakeDvcPointUsageRepository({this.onSave});

  final List<DvcPointUsage> savedUsages = [];
  final List<String> deletedUsageIds = [];
  final List<String> deletedGroupIds = [];
  final void Function(DvcPointUsage pointUsage)? onSave;

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
    onSave?.call(pointUsage);
  }
}
