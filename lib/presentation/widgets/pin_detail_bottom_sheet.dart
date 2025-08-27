import 'package:flutter/material.dart';
import '../../domain/entities/pin.dart';
import '../../domain/services/nearby_location_service.dart';
import '../../domain/value-objects/location.dart';
import '../../infrastructure/services/google_places_api_nearby_location_service.dart';
import '../../env/env.dart';
import '../utils/date_picker_utils.dart';

class PinDetailBottomSheet extends StatefulWidget {
  final Pin pin;
  final VoidCallback onClose;
  final Function(Pin pin)? onUpdate;
  final Function(String)? onDelete;

  const PinDetailBottomSheet({
    super.key,
    required this.pin,
    required this.onClose,
    this.onUpdate,
    this.onDelete,
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

  String? _locationName;
  bool _isLoadingLocation = false;
  final NearbyLocationService _reverseGeocodingService =
      GooglePlacesApiNearbyLocationService(apiKey: Env.googlePlacesApiKey);

  @override
  void initState() {
    super.initState();
    _initializeFromPin();
    _loadLocationName();
  }

  @override
  void didUpdateWidget(PinDetailBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pin != oldWidget.pin) {
      _initializeFromPin();
      _loadLocationName();
    }
  }

  void _initializeFromPin() {
    final pin = widget.pin;

    fromDate = null;
    fromTime = null;
    toDate = null;
    toTime = null;
    memoController.clear();

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

  Future<void> _loadLocationName() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final location = Location(
        latitude: widget.pin.latitude,
        longitude: widget.pin.longitude,
      );
      final locationName = await _reverseGeocodingService.getLocationName(
        location,
      );
      setState(() {
        _locationName = locationName;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationName = null;
        _isLoadingLocation = false;
      });
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
      builder: (context, scrollController) =>
          _buildBottomSheetContent(scrollController),
    );
  }

  Widget _buildBottomSheetContent(ScrollController scrollController) {
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
            _buildDragHandle(),
            _buildCloseButton(),
            _buildMainContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        32,
        0,
        32,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationSection(),
          const SizedBox(height: 16),
          _buildDateTimeSection(),
          const SizedBox(height: 16),
          _buildMemoField(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
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

  Widget _buildCloseButton() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, right: 16),
        child: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
        ),
      ),
    );
  }

  Widget _buildDateTimeField({
    required String value,
    required VoidCallback onTap,
    required IconData icon,
    Key? testKey,
  }) {
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

  String _formatDate(DateTime? date) {
    if (date == null) return '日付を選択';
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '時間を選択';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('訪問開始日'),
        const SizedBox(height: 8),
        _buildDateTimeField(
          testKey: const Key('visitStartDateField'),
          value: _formatDate(fromDate),
          onTap: () => _selectFromDate(context),
          icon: Icons.calendar_today,
        ),
        const SizedBox(height: 8),
        _buildDateTimeField(
          testKey: const Key('visitStartTimeField'),
          value: _formatTime(fromTime),
          onTap: () => _selectFromTime(context),
          icon: Icons.access_time,
        ),
        const SizedBox(height: 16),
        const Text('訪問終了日'),
        const SizedBox(height: 8),
        _buildDateTimeField(
          testKey: const Key('visitEndDateField'),
          value: _formatDate(toDate),
          onTap: () => _selectToDate(context),
          icon: Icons.calendar_today,
        ),
        const SizedBox(height: 8),
        _buildDateTimeField(
          testKey: const Key('visitEndTimeField'),
          value: _formatTime(toTime),
          onTap: () => _selectToTime(context),
          icon: Icons.access_time,
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
      ],
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.blue[600]),
          const SizedBox(width: 8),
          Expanded(
            child: _isLoadingLocation
                ? const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('場所を取得中...'),
                    ],
                  )
                : Text(
                    _locationName ?? '場所情報を取得できませんでした',
                    style: TextStyle(
                      color: _locationName != null
                          ? Colors.black87
                          : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoField() {
    return TextFormField(
      key: const Key('visitMemoField'),
      minLines: 4,
      maxLines: null,
      controller: memoController,
      decoration: const InputDecoration(
        labelText: 'メモ',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(onPressed: _handleDelete, child: const Text('削除')),
        ElevatedButton(onPressed: _handleUpdate, child: const Text('更新')),
      ],
    );
  }

  void _handleDelete() {
    if (widget.onDelete != null) {
      widget.onDelete!(widget.pin.pinId);
    }
  }

  void _handleUpdate() {
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

    if (widget.onUpdate != null) {
      final pin = widget.pin.copyWith(
        visitStartDate: fromDateTime,
        visitEndDate: toDateTime,
        visitMemo: memoController.text,
      );
      widget.onUpdate!(pin);
    }
  }
}
