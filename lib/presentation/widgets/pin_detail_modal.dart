import 'package:flutter/material.dart';

class PinDetailModal extends StatefulWidget {
  final VoidCallback? onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onClose;

  const PinDetailModal({super.key, this.onSave, this.onDelete, this.onClose});

  @override
  State<PinDetailModal> createState() => _PinDetailModalState();
}

class _PinDetailModalState extends State<PinDetailModal> {
  DateTime? fromDate;
  DateTime? toDate;
  final TextEditingController memoController = TextEditingController();

  Future<void> _selectFromDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        fromDate = picked;
      });
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: toDate ?? (fromDate ?? DateTime.now()),
      firstDate: fromDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        toDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // 閉じるボタン
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 16, right: 16),
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                32,
                16,
                32,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('旅行期間From'),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectFromDate(context),
                    child: AbsorbPointer(
                      child: TextFormField(
                        key: const Key('fromDateField'),
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: '日付を選択',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        controller: TextEditingController(
                          text: fromDate != null
                              ? '${fromDate!.year}/${fromDate!.month}/${fromDate!.day}'
                              : '',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('旅行期間To'),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectToDate(context),
                    child: AbsorbPointer(
                      child: TextFormField(
                        key: const Key('toDateField'),
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: '日付を選択',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        controller: TextEditingController(
                          text: toDate != null
                              ? '${toDate!.year}/${toDate!.month}/${toDate!.day}'
                              : '',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('旅の記録'),
                  SizedBox(height: 8),
                  TextFormField(
                    key: const Key('memoField'),
                    minLines: 4,
                    maxLines: null,
                    controller: memoController,
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
            child: Divider(
              thickness: 1,
              height: 1,
              color:
                  Theme.of(
                    context,
                  ).inputDecorationTheme.enabledBorder?.borderSide.color ??
                  Colors.black45,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: widget.onDelete,
                  child: const Text('削除'),
                ),
                ElevatedButton(
                  onPressed: widget.onSave,
                  child: const Text('保存'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
