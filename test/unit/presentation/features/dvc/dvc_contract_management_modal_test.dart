import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/infrastructure/time/fixed_app_clock.dart';
import 'package:memora/presentation/features/dvc/dvc_contract_management_modal.dart';

void main() {
  test('契約の編集開始時の期待バージョンを入力変更後も保持する', () {
    final dynamic editable = DvcEditableContract.fromDto(DvcPointContractDto(
      id: 'contract', groupId: 'group', version: 7, contractName: '契約',
      contractStartYearMonth: DateTime(2026), contractEndYearMonth: DateTime(2027),
      useYearStartMonth: 1, annualPoint: 100,
    ), expanded: true).copyWith(contractName: '変更後');
    expect(editable.version, 7);
  });

  final month = DateTime(2026, 1);
  final contracts = [
    for (final name in ['A', 'B'])
      DvcPointContractDto(
        id: name,
        groupId: 'g1',
        contractName: '契約$name',
        contractStartYearMonth: month,
        contractEndYearMonth: month,
        useYearStartMonth: 1,
        annualPoint: 100,
      ),
  ];

  testWidgets('閉じた契約に削除操作を出さず、開閉後に明示的な削除操作で対象だけ除外する', (tester) async {
    List<DvcEditableContract>? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDvcContractManagementModal(
                context: context,
                contracts: contracts,
                clock: FixedAppClock(month),
                onSave: (values) async {
                  saved = values.toList();
                  return true;
                },
              ),
              child: const Text('契約管理を開く'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('契約管理を開く'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('dvc_contract_delete_button_0')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('dvc_contract_delete_button_1')),
      findsNothing,
    );

    await tester.tap(find.widgetWithText(ListTile, '契約A'));
    await tester.pumpAndSettle();
    expect(find.text('この契約を削除'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, '契約A'));
    await tester.pumpAndSettle();
    expect(find.text('この契約を削除'), findsNothing);
    expect(find.text('契約A'), findsOneWidget);

    await tester.tap(find.widgetWithText(ListTile, '契約A'));
    await tester.pumpAndSettle();
    final deleteButton = find.byKey(
      const ValueKey('dvc_contract_delete_button_0'),
    );
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(find.text('契約A'), findsNothing);
    expect(find.text('契約B'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '更新'));
    await tester.pumpAndSettle();
    expect(saved!.map((v) => v.id), ['B']);
  });
}
