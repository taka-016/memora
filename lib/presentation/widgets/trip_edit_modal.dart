import 'package:flutter/material.dart';
import '../../domain/entities/trip_entry.dart';
import 'map_display.dart';
import 'map_display_placeholder.dart';

class TripEditModal extends StatefulWidget {
  final String groupId;
  final TripEntry? tripEntry;
  final Function(TripEntry) onSave;
  final bool isTestEnvironment;
  final int? year;

  const TripEditModal({
    super.key,
    required this.groupId,
    this.tripEntry,
    required this.onSave,
    this.isTestEnvironment = false,
    this.year,
  });

  @override
  State<TripEditModal> createState() => _TripEditModalState();
}

class _TripEditModalState extends State<TripEditModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _memoController;
  late TextEditingController _visitLocationController;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _dateErrorMessage;
  bool _isMapExpanded = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _mapIconKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.tripEntry?.tripName ?? '',
    );
    _memoController = TextEditingController(
      text: widget.tripEntry?.tripMemo ?? '',
    );
    _visitLocationController = TextEditingController();
    _startDate = widget.tripEntry?.tripStartDate;
    _endDate = widget.tripEntry?.tripEndDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _memoController.dispose();
    _visitLocationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleMapExpansion() {
    setState(() {
      _isMapExpanded = !_isMapExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      child: Material(
        type: MaterialType.card,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24.0),
          child: _isMapExpanded
              ? _buildMapExpandedLayout()
              : _buildNormalLayout(),
        ),
      ),
    );
  }

  Widget _buildNormalLayout() {
    final isEditing = widget.tripEntry != null;

    return Column(
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
            controller: _scrollController,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '旅行名',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDatePickerField(
                    labelText: '旅行期間 From',
                    selectedDate: _startDate,
                    onDateSelected: (date) {
                      setState(() {
                        _startDate = date;
                        _dateErrorMessage = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDatePickerField(
                    labelText: '旅行期間 To',
                    selectedDate: _endDate,
                    onDateSelected: (date) {
                      setState(() {
                        _endDate = date;
                        _dateErrorMessage = null;
                      });
                    },
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
                    controller: _memoController,
                    decoration: const InputDecoration(
                      labelText: 'メモ',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _visitLocationController,
                          decoration: const InputDecoration(
                            labelText: '訪問場所',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        key: _mapIconKey,
                        onPressed: _toggleMapExpansion,
                        icon: const Icon(Icons.map),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildMapExpandedLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '地図で場所を選択',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            IconButton(
              key: _mapIconKey,
              onPressed: _toggleMapExpansion,
              icon: const Icon(Icons.map_outlined),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: widget.isTestEnvironment
              ? Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    child: MapDisplayPlaceholder(),
                  ),
                )
              : const MapDisplay(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final isEditing = widget.tripEntry != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _dateErrorMessage = null;
            });

            if (_startDate == null || _endDate == null) {
              setState(() {
                _dateErrorMessage = '開始日と終了日を選択してください';
              });
              return;
            }

            if (_startDate!.isAfter(_endDate!)) {
              setState(() {
                _dateErrorMessage = '開始日は終了日より前の日付を選択してください';
              });
              return;
            }

            if (widget.year != null &&
                (_startDate!.year != widget.year! ||
                    _endDate!.year != widget.year!)) {
              setState(() {
                _dateErrorMessage = '開始日と終了日は${widget.year}年の日付を選択してください';
              });
              return;
            }

            if (_formKey.currentState!.validate()) {
              final tripEntry = TripEntry(
                id: widget.tripEntry?.id ?? '',
                groupId: widget.groupId,
                tripName: _nameController.text.isEmpty
                    ? null
                    : _nameController.text,
                tripStartDate: _startDate!,
                tripEndDate: _endDate!,
                tripMemo: _memoController.text.isEmpty
                    ? null
                    : _memoController.text,
              );

              widget.onSave(tripEntry);
              Navigator.of(context).pop();
            }
          },
          child: Text(isEditing ? '更新' : '作成'),
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required String labelText,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          onDateSelected(date);
        }
      },
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
              selectedDate != null
                  ? '${selectedDate.year}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.day.toString().padLeft(2, '0')}'
                  : labelText,
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
            const Icon(Icons.calendar_today, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}
