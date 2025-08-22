import 'package:flutter/material.dart';
import '../../domain/entities/pin.dart';
import '../utils/date_picker_utils.dart';

class PinDetailBottomSheet extends StatefulWidget {
  final Function(Pin pin)? onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onClose;
  final Pin? pin;

  const PinDetailBottomSheet({
    super.key,
    this.pin,
    this.onSave,
    this.onDelete,
    this.onClose,
  });

  @override
  State<PinDetailBottomSheet> createState() => _PinDetailBottomSheetState();
}

class _PinDetailBottomSheetState extends State<PinDetailBottomSheet> {
  DateTime? fromDate;
  TimeOfDay? fromTime;
  DateTime? toDate;
  TimeOfDay? toTime;
  final TextEditingController memoController = TextEditingController();
  String? _dateErrorMessage;

  @override
  void initState() {
    super.initState();
    _initializeFromPin();
  }

  void _initializeFromPin() {
    if (widget.pin != null) {
      final pin = widget.pin!;

      if (pin.visitStartDate != null) {
        fromDate = DateTime(
          pin.visitStartDate!.year,
          pin.visitStartDate!.month,
          pin.visitStartDate!.day,
        );
        fromTime = TimeOfDay(
          hour: pin.visitStartDate!.hour,
          minute: pin.visitStartDate!.minute,
        );
      }

      if (pin.visitEndDate != null) {
        toDate = DateTime(
          pin.visitEndDate!.year,
          pin.visitEndDate!.month,
          pin.visitEndDate!.day,
        );
        toTime = TimeOfDay(
          hour: pin.visitEndDate!.hour,
          minute: pin.visitEndDate!.minute,
        );
      }

      if (pin.visitMemo != null) {
        memoController.text = pin.visitMemo!;
      }
    }
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final picked = await DatePickerUtils.showCustomDatePicker(
      context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        fromDate = picked;
        _dateErrorMessage = null;
      });
    }
  }

  Future<void> _selectFromTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: fromTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        fromTime = picked;
        _dateErrorMessage = null;
      });
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final picked = await DatePickerUtils.showCustomDatePicker(
      context,
      initialDate: toDate ?? (fromDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        toDate = picked;
        _dateErrorMessage = null;
      });
    }
  }

  Future<void> _selectToTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: toTime ?? (fromTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        toTime = picked;
        _dateErrorMessage = null;
      });
    }
  }

  DateTime? get fromDateTime {
    if (fromDate == null) return null;
    final time = fromTime ?? const TimeOfDay(hour: 0, minute: 0);
    return DateTime(
      fromDate!.year,
      fromDate!.month,
      fromDate!.day,
      time.hour,
      time.minute,
    );
  }

  DateTime? get toDateTime {
    if (toDate == null) return null;
    final time = toTime ?? const TimeOfDay(hour: 0, minute: 0);
    return DateTime(
      toDate!.year,
      toDate!.month,
      toDate!.day,
      time.hour,
      time.minute,
    );
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
                        onTap: () => _selectFromDate(context),
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
                                fromDate != null
                                    ? '${fromDate!.year}/${fromDate!.month.toString().padLeft(2, '0')}/${fromDate!.day.toString().padLeft(2, '0')}'
                                    : '日付を選択',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        key: const Key('visitStartTimeField'),
                        onTap: () => _selectFromTime(context),
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
                                fromTime != null
                                    ? '${fromTime!.hour.toString().padLeft(2, '0')}:${fromTime!.minute.toString().padLeft(2, '0')}'
                                    : '時間を選択',
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
                        onTap: () => _selectToDate(context),
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
                                toDate != null
                                    ? '${toDate!.year}/${toDate!.month.toString().padLeft(2, '0')}/${toDate!.day.toString().padLeft(2, '0')}'
                                    : '日付を選択',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        key: const Key('visitEndTimeField'),
                        onTap: () => _selectToTime(context),
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
                                toTime != null
                                    ? '${toTime!.hour.toString().padLeft(2, '0')}:${toTime!.minute.toString().padLeft(2, '0')}'
                                    : '時間を選択',
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
                      if (_dateErrorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _dateErrorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
                              setState(() {
                                _dateErrorMessage = null;
                              });

                              if (fromDateTime != null && toDateTime != null) {
                                if (fromDateTime!.isAfter(toDateTime!)) {
                                  setState(() {
                                    _dateErrorMessage =
                                        '訪問開始日時は訪問終了日時より前の日時を選択してください';
                                  });
                                  return;
                                }
                              }

                              if (widget.onSave != null) {
                                final pin = Pin(
                                  id: widget.pin?.id ?? '',
                                  pinId: widget.pin?.pinId ?? '',
                                  tripId: widget.pin?.tripId,
                                  latitude: widget.pin?.latitude ?? 0.0,
                                  longitude: widget.pin?.longitude ?? 0.0,
                                  visitStartDate: fromDateTime,
                                  visitEndDate: toDateTime,
                                  visitMemo: memoController.text,
                                );
                                widget.onSave!(pin);
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
