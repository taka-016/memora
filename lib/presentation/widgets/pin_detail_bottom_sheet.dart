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
                const _DragHandle(),
                _CloseButton(onClose: widget.onClose),
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
                      _DateTimeSection(
                        fromDate: fromDate,
                        fromTime: fromTime,
                        toDate: toDate,
                        toTime: toTime,
                        onSelectFromDate: () => _selectFromDate(context),
                        onSelectFromTime: () => _selectFromTime(context),
                        onSelectToDate: () => _selectToDate(context),
                        onSelectToTime: () => _selectToTime(context),
                        dateErrorMessage: _dateErrorMessage,
                      ),
                      const SizedBox(height: 16),
                      _MemoField(controller: memoController),
                      const SizedBox(height: 24),
                      _ActionButtons(
                        onDelete: widget.onDelete,
                        onSave: _handleSave,
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

  void _handleSave() {
    setState(() {
      _dateErrorMessage = null;
    });

    if (fromDateTime != null && toDateTime != null) {
      if (fromDateTime!.isAfter(toDateTime!)) {
        setState(() {
          _dateErrorMessage = '訪問開始日時は訪問終了日時より前の日時を選択してください';
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
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, right: 16),
        child: IconButton(icon: const Icon(Icons.close), onPressed: onClose),
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.value,
    required this.onTap,
    required this.icon,
    this.testKey,
  });

  final String value;
  final VoidCallback onTap;
  final IconData icon;
  final Key? testKey;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: testKey,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black54),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
            Icon(icon, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

class _DateTimeSection extends StatelessWidget {
  const _DateTimeSection({
    required this.fromDate,
    required this.fromTime,
    required this.toDate,
    required this.toTime,
    required this.onSelectFromDate,
    required this.onSelectFromTime,
    required this.onSelectToDate,
    required this.onSelectToTime,
    this.dateErrorMessage,
  });

  final DateTime? fromDate;
  final TimeOfDay? fromTime;
  final DateTime? toDate;
  final TimeOfDay? toTime;
  final VoidCallback onSelectFromDate;
  final VoidCallback onSelectFromTime;
  final VoidCallback onSelectToDate;
  final VoidCallback onSelectToTime;
  final String? dateErrorMessage;

  String _formatDate(DateTime? date) {
    if (date == null) return '日付を選択';
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '時間を選択';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('訪問開始日'),
        const SizedBox(height: 8),
        _DateTimeField(
          testKey: const Key('visitStartDateField'),
          value: _formatDate(fromDate),
          onTap: onSelectFromDate,
          icon: Icons.calendar_today,
        ),
        const SizedBox(height: 8),
        _DateTimeField(
          testKey: const Key('visitStartTimeField'),
          value: _formatTime(fromTime),
          onTap: onSelectFromTime,
          icon: Icons.access_time,
        ),
        const SizedBox(height: 16),
        const Text('訪問終了日'),
        const SizedBox(height: 8),
        _DateTimeField(
          testKey: const Key('visitEndDateField'),
          value: _formatDate(toDate),
          onTap: onSelectToDate,
          icon: Icons.calendar_today,
        ),
        const SizedBox(height: 8),
        _DateTimeField(
          testKey: const Key('visitEndTimeField'),
          value: _formatTime(toTime),
          onTap: onSelectToTime,
          icon: Icons.access_time,
        ),
        if (dateErrorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            dateErrorMessage!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _MemoField extends StatelessWidget {
  const _MemoField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const Key('visitMemoField'),
      minLines: 4,
      maxLines: null,
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'メモ',
        border: OutlineInputBorder(),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onDelete, required this.onSave});

  final VoidCallback? onDelete;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(onPressed: onDelete, child: const Text('削除')),
        ElevatedButton(onPressed: onSave, child: const Text('保存')),
      ],
    );
  }
}
