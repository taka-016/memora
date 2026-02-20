import 'package:flutter/material.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';
import 'package:memora/presentation/features/dvc/dvc_point_calculation_date_utils.dart';

typedef DvcContractSaveCallback =
    Future<void> Function(List<DvcEditableContract> contracts);

Future<void> showDvcContractManagementModal({
  required BuildContext context,
  required List<DvcPointContractDto> contracts,
  required DvcContractSaveCallback onSave,
}) async {
  final editable = contracts
      .map(
        (contract) => DvcEditableContract.fromDto(
          contract,
          expanded: contracts.length == 1,
        ),
      )
      .toList();
  if (editable.isEmpty) {
    editable.add(
      DvcEditableContract(
        contractName: '',
        contractStartYearMonth: dvcMonthStart(DateTime.now()),
        contractEndYearMonth: dvcMonthStart(DateTime.now()),
        useYearStartMonth: DateTime.now().month,
        annualPointText: '',
        expanded: true,
      ),
    );
  }
  var validationError = '';

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('契約管理'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...editable.asMap().entries.map((entry) {
                      final index = entry.key;
                      final contract = entry.value;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  contract.contractName.isEmpty
                                      ? '新しい契約'
                                      : contract.contractName,
                                ),
                                trailing: Icon(
                                  contract.expanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                ),
                                onTap: () {
                                  setState(() {
                                    editable[index] = contract.copyWith(
                                      expanded: !contract.expanded,
                                    );
                                  });
                                },
                              ),
                              if (contract.expanded)
                                _ContractForm(
                                  contract: contract,
                                  onChanged: (updated) {
                                    setState(() {
                                      editable[index] = updated;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        key: const Key('dvc_contract_add_button'),
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setState(() {
                            editable.add(
                              DvcEditableContract(
                                contractName: '',
                                contractStartYearMonth: dvcMonthStart(
                                  DateTime.now(),
                                ),
                                contractEndYearMonth: dvcMonthStart(
                                  DateTime.now(),
                                ),
                                useYearStartMonth: DateTime.now().month,
                                annualPointText: '',
                                expanded: true,
                              ),
                            );
                          });
                        },
                      ),
                    ),
                    if (validationError.isNotEmpty)
                      Text(
                        validationError,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () async {
                  final hasInvalid = editable.any(
                    (contract) => !contract.isValid,
                  );
                  if (hasInvalid) {
                    setState(() {
                      validationError = '入力内容を確認してください';
                    });
                    return;
                  }
                  Navigator.of(dialogContext).pop();
                  await onSave(editable);
                },
                child: const Text('更新'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _YearMonthSelector extends StatelessWidget {
  const _YearMonthSelector({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selected,
              firstDate: DateTime(2000, 1),
              lastDate: DateTime(2100, 12),
            );
            if (picked == null) {
              return;
            }
            onSelected(DateTime(picked.year, picked.month));
          },
          child: Text(dvcFormatYearMonth(selected)),
        ),
      ],
    );
  }
}

class _ContractForm extends StatelessWidget {
  const _ContractForm({required this.contract, required this.onChanged});

  final DvcEditableContract contract;
  final ValueChanged<DvcEditableContract> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: contract.contractName,
          decoration: const InputDecoration(labelText: '契約名'),
          onChanged: (value) {
            onChanged(contract.copyWith(contractName: value));
          },
        ),
        _YearMonthSelector(
          label: '契約開始年月',
          selected: contract.contractStartYearMonth,
          onSelected: (value) {
            onChanged(contract.copyWith(contractStartYearMonth: value));
          },
        ),
        _YearMonthSelector(
          label: '契約終了年月',
          selected: contract.contractEndYearMonth,
          onSelected: (value) {
            onChanged(contract.copyWith(contractEndYearMonth: value));
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('ユースイヤー開始月'),
            const SizedBox(width: 16),
            DropdownButton<int>(
              value: contract.useYearStartMonth,
              items: List.generate(
                12,
                (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text('${index + 1}月'),
                ),
              ),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                onChanged(contract.copyWith(useYearStartMonth: value));
              },
            ),
          ],
        ),
        TextFormField(
          initialValue: contract.annualPointText,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '年間ポイント'),
          onChanged: (value) {
            onChanged(contract.copyWith(annualPointText: value));
          },
        ),
      ],
    );
  }
}

class DvcEditableContract {
  DvcEditableContract({
    required this.contractName,
    required this.contractStartYearMonth,
    required this.contractEndYearMonth,
    required this.useYearStartMonth,
    required this.annualPointText,
    required this.expanded,
  });

  factory DvcEditableContract.fromDto(
    DvcPointContractDto dto, {
    required bool expanded,
  }) {
    return DvcEditableContract(
      contractName: dto.contractName,
      contractStartYearMonth: dvcMonthStart(dto.contractStartYearMonth),
      contractEndYearMonth: dvcMonthStart(dto.contractEndYearMonth),
      useYearStartMonth: dto.useYearStartMonth,
      annualPointText: dto.annualPoint.toString(),
      expanded: expanded,
    );
  }

  final String contractName;
  final DateTime contractStartYearMonth;
  final DateTime contractEndYearMonth;
  final int useYearStartMonth;
  final String annualPointText;
  final bool expanded;

  int get annualPoint => int.tryParse(annualPointText) ?? 0;

  bool get isValid {
    return contractName.trim().isNotEmpty &&
        annualPoint > 0 &&
        !contractEndYearMonth.isBefore(contractStartYearMonth);
  }

  DvcPointContract toEntity(String groupId) {
    return DvcPointContract(
      id: '',
      groupId: groupId,
      contractName: contractName.trim(),
      contractStartYearMonth: contractStartYearMonth,
      contractEndYearMonth: contractEndYearMonth,
      useYearStartMonth: useYearStartMonth,
      annualPoint: annualPoint,
    );
  }

  DvcEditableContract copyWith({
    String? contractName,
    DateTime? contractStartYearMonth,
    DateTime? contractEndYearMonth,
    int? useYearStartMonth,
    String? annualPointText,
    bool? expanded,
  }) {
    return DvcEditableContract(
      contractName: contractName ?? this.contractName,
      contractStartYearMonth:
          contractStartYearMonth ?? this.contractStartYearMonth,
      contractEndYearMonth: contractEndYearMonth ?? this.contractEndYearMonth,
      useYearStartMonth: useYearStartMonth ?? this.useYearStartMonth,
      annualPointText: annualPointText ?? this.annualPointText,
      expanded: expanded ?? this.expanded,
    );
  }
}
