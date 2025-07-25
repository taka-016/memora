import 'package:flutter/material.dart';
import '../../domain/entities/trip_entry.dart';

class TripManagementModal extends StatefulWidget {
  final String groupId;
  final TripEntry? tripEntry;
  final Function(TripEntry) onSave;

  const TripManagementModal({
    super.key,
    required this.groupId,
    this.tripEntry,
    required this.onSave,
  });

  @override
  State<TripManagementModal> createState() => _TripManagementModalState();
}

class _TripManagementModalState extends State<TripManagementModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tripNameController;
  late TextEditingController _tripMemoController;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tripNameController = TextEditingController(
      text: widget.tripEntry?.tripName ?? '',
    );
    _tripMemoController = TextEditingController(
      text: widget.tripEntry?.tripMemo ?? '',
    );
    _startDate = widget.tripEntry?.tripStartDate;
    _endDate = widget.tripEntry?.tripEndDate;
  }

  @override
  void dispose() {
    _tripNameController.dispose();
    _tripMemoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.tripEntry != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? '旅行編集' : '旅行新規作成',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        key: const Key('trip_name_field'),
                        controller: _tripNameController,
                        decoration: const InputDecoration(
                          labelText: '旅行名',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('start_date_field'),
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: '開始日',
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today),
                          hintText: _startDate != null
                              ? '${_startDate!.year}/${_startDate!.month}/${_startDate!.day}'
                              : '開始日を選択してください',
                        ),
                        validator: (value) {
                          if (_startDate == null) {
                            return '開始日を入力してください';
                          }
                          return null;
                        },
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(() {
                              _startDate = date;
                              // 開始日が終了日より後の場合、終了日をクリア
                              if (_endDate != null &&
                                  _endDate!.isBefore(date)) {
                                _endDate = null;
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('end_date_field'),
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: '終了日',
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today),
                          hintText: _endDate != null
                              ? '${_endDate!.year}/${_endDate!.month}/${_endDate!.day}'
                              : '終了日を選択してください',
                        ),
                        validator: (value) {
                          if (_endDate == null) {
                            return '終了日を入力してください';
                          }
                          if (_startDate != null &&
                              _endDate!.isBefore(_startDate!)) {
                            return '終了日は開始日以降を選択してください';
                          }
                          return null;
                        },
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate:
                                _endDate ?? _startDate ?? DateTime.now(),
                            firstDate: _startDate ?? DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(() {
                              _endDate = date;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('trip_memo_field'),
                        controller: _tripMemoController,
                        decoration: const InputDecoration(
                          labelText: '旅の記録',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final tripEntry = TripEntry(
                        id: widget.tripEntry?.id ?? '',
                        groupId: widget.groupId,
                        tripName: _tripNameController.text.isEmpty
                            ? null
                            : _tripNameController.text,
                        tripStartDate: _startDate!,
                        tripEndDate: _endDate!,
                        tripMemo: _tripMemoController.text.isEmpty
                            ? null
                            : _tripMemoController.text,
                      );

                      widget.onSave(tripEntry);
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(isEditing ? '更新' : '作成'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
