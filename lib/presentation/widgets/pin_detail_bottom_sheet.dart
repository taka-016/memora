import 'package:flutter/material.dart';
import '../utils/date_picker_utils.dart';

class PinDetailBottomSheet extends StatefulWidget {
  final Function(DateTime? fromDateTime, DateTime? toDateTime, String memo)?
  onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onClose;

  const PinDetailBottomSheet({
    super.key,
    this.onSave,
    this.onDelete,
    this.onClose,
  });

  @override
  State<PinDetailBottomSheet> createState() => _PinDetailBottomSheetState();
}

class _PinDetailBottomSheetState extends State<PinDetailBottomSheet> {
  DateTime? fromDateTime;
  DateTime? toDateTime;
  final TextEditingController memoController = TextEditingController();

  Future<void> _selectFromDateTime(BuildContext context) async {
    final picked = await DatePickerUtils.showCustomDateTimePicker(
      context,
      initialDateTime: fromDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        fromDateTime = picked;
      });
    }
  }

  Future<void> _selectToDateTime(BuildContext context) async {
    final picked = await DatePickerUtils.showCustomDateTimePicker(
      context,
      initialDateTime: toDateTime ?? (fromDateTime ?? DateTime.now()),
      firstDate: fromDateTime ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        toDateTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Material(
          type: MaterialType.card,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                // ドラッグハンドル
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 閉じるボタン
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 16),
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onClose,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    32,
                    0,
                    32,
                    16 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('訪問開始日'),
                      const SizedBox(height: 8),
                      InkWell(
                        key: const Key('visitStartDateField'),
                        onTap: () => _selectFromDateTime(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black54),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                fromDateTime != null
                                    ? '${fromDateTime!.year}/${fromDateTime!.month.toString().padLeft(2, '0')}/${fromDateTime!.day.toString().padLeft(2, '0')} ${fromDateTime!.hour.toString().padLeft(2, '0')}:${fromDateTime!.minute.toString().padLeft(2, '0')}'
                                    : '日時を選択',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              const Icon(
                                Icons.access_time,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('訪問終了日'),
                      const SizedBox(height: 8),
                      InkWell(
                        key: const Key('visitEndDateField'),
                        onTap: () => _selectToDateTime(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black54),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                toDateTime != null
                                    ? '${toDateTime!.year}/${toDateTime!.month.toString().padLeft(2, '0')}/${toDateTime!.day.toString().padLeft(2, '0')} ${toDateTime!.hour.toString().padLeft(2, '0')}:${toDateTime!.minute.toString().padLeft(2, '0')}'
                                    : '日時を選択',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              const Icon(
                                Icons.access_time,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('visitMemoField'),
                        minLines: 4,
                        maxLines: null,
                        controller: memoController,
                        decoration: const InputDecoration(
                          labelText: 'メモ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: widget.onDelete,
                            child: const Text('削除'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (widget.onSave != null) {
                                widget.onSave!(
                                  fromDateTime,
                                  toDateTime,
                                  memoController.text,
                                );
                              }
                            },
                            child: const Text('保存'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
