import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/usecases/dvc/calculate_dvc_point_table_usecase.dart';
import 'package:memora/infrastructure/time/fixed_app_clock.dart';
import 'package:memora/presentation/features/dvc/dvc_contract_management_modal.dart';
import 'package:memora/presentation/features/dvc/dvc_usage_registration_modal.dart';
import 'package:memora/presentation/features/dvc/dvc_limited_point_registration_modal.dart';
import 'package:memora/presentation/features/dvc/dvc_usage_breakdown_modal.dart';
import 'package:memora/presentation/features/dvc/dvc_available_breakdown_modal.dart';

void main() {
  final month = DateTime(2026, 1);
  final contracts = [
    DvcPointContractDto(
      id: 'c1',
      groupId: 'g1',
      contractName: '契約',
      contractStartYearMonth: month,
      contractEndYearMonth: month,
      useYearStartMonth: 1,
      annualPoint: 100,
    ),
  ];
  for (final kind in ['契約', '利用登録', '限定登録', '利用削除', '限定削除']) {
    testWidgets('$kindは保存待ち中の再操作と閉じる操作を抑止し、拒否後に再試行できる', (tester) async {
      var pending = Completer<bool>();
      var calls = 0;
      Future<bool> save() {
        calls++;
        return pending.future;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  switch (kind) {
                    case '契約':
                      return showDvcContractManagementModal(
                        context: context,
                        contracts: contracts,
                        clock: FixedAppClock(month),
                        onSave: (_) => save(),
                      );
                    case '利用登録':
                      return showDvcUsageRegistrationModal(
                        context: context,
                        contracts: contracts,
                        targetYearMonth: month,
                        availablePointsByContract: {'c1': 100},
                        onSave: ({
                          required contractId,
                          required usageYearMonth,
                          required usedPoint,
                          required memo,
                        }) => save(),
                      );
                    case '限定登録':
                      return showDvcLimitedPointRegistrationModal(
                        context: context,
                        contracts: contracts,
                        clock: FixedAppClock(month),
                        onSave: ({
                          required contractId,
                          required startYearMonth,
                          required endYearMonth,
                          required point,
                          required memo,
                        }) => save(),
                      );
                    case '利用削除':
                      return showDvcUsageBreakdownModal(
                        context: context,
                        month: month,
                        contracts: contracts,
                        usages: [
                          DvcPointUsageDto(
                            id: 'u1',
                            groupId: 'g1',
                            contractId: 'c1',
                            usageYearMonth: month,
                            usedPoint: 10,
                          ),
                        ],
                        onDelete: (_) => save(),
                      );
                    default:
                      return showDvcAvailableBreakdownModal(
                        context: context,
                        month: month,
                        breakdowns: [
                          DvcAvailablePointBreakdown(
                            sourceType: DvcPointSourceType.limited,
                            sourceId: 'l1',
                            contractId: 'c1',
                            sourceName: '限定',
                            remainingPoint: 10,
                            contractName: '契約',
                            availableFrom: month,
                            expireAt: month,
                          ),
                        ],
                        onDeleteLimitedPoint: (_) => save(),
                      );
                  }
                },
                child: const Text('開く'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();
      if (kind == '利用登録' || kind == '限定登録') {
        await tester.enterText(
          find.byKey(
            Key(
              kind == '利用登録'
                  ? 'dvc_usage_point_field'
                  : 'dvc_limited_point_field',
            ),
          ),
          '10',
        );
      }
      final deleting = kind.endsWith('削除');
      Future<void> submit() async {
        if (deleting) {
          await tester.tap(find.byIcon(Icons.delete_outline));
          await tester.pumpAndSettle();
          await tester.tap(find.text('削除'));
        } else {
          await tester.tap(find.text(kind == '契約' ? '更新' : '登録'));
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      await submit();
      expect(calls, 1);
      final close = tester.widget<TextButton>(
        find.widgetWithText(TextButton, deleting ? '閉じる' : 'キャンセル'),
      );
      expect(close.onPressed, isNull);
      await tester.tapAt(const Offset(1, 1));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(calls, 1);
      pending.complete(false);
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);
      pending = Completer<bool>();
      await submit();
      expect(calls, 2);
      pending.complete(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AlertDialog), findsNothing);
    });
  }
}
