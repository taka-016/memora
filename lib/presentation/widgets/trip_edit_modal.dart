import 'package:flutter/material.dart';
import 'package:memora/domain/value-objects/location.dart';
import '../../domain/entities/trip_entry.dart';
import '../../domain/entities/pin.dart';
import '../utils/date_picker_utils.dart';
import '../../infrastructure/factories/map_view_factory.dart';

import 'package:uuid/uuid.dart';

class TripEditModal extends StatefulWidget {
  final String groupId;
  final TripEntry? tripEntry;
  final List<Pin>? pins;
  final Function(TripEntry, {List<Pin>? pins}) onSave;
  final bool isTestEnvironment;
  final int? year;

  const TripEditModal({
    super.key,
    required this.groupId,
    this.tripEntry,
    this.pins,
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

  // 地図とピン管理用の変数
  List<Pin> _pins = [];
  Pin? _selectedPin;

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

    if (widget.pins != null) {
      _pins = List.from(widget.pins!);
    }
  }

  Future<void> _onMapLongTapped(Location location) async {
    final uuid = Uuid();
    final pinId = uuid.v4();
    final newPin = Pin(
      id: pinId,
      pinId: pinId,
      latitude: location.latitude,
      longitude: location.longitude,
    );

    setState(() {
      _pins.add(newPin);
      _selectedPin = newPin;
    });
  }

  Future<void> _onPinDeleted(String pinId) async {
    setState(() {
      _pins.removeWhere((pin) => pin.pinId == pinId);
      if (_selectedPin?.pinId == pinId) {
        _selectedPin = null;
      }
    });
  }

  void _onPinTapped(Pin pin) {
    // ピンタップ時の処理（必要に応じて実装）
  }

  void _onPinUpdated(Pin pin) {
    setState(() {
      final index = _pins.indexWhere((p) => p.pinId == pin.pinId);
      if (index != -1) {
        _pins[index] = pin;
      }
    });
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        Expanded(child: _buildForm()),
        const SizedBox(height: 24),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildHeader() {
    final isEditing = widget.tripEntry != null;
    return Text(
      isEditing ? '旅行編集' : '旅行新規作成',
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTripNameField(),
            const SizedBox(height: 16),
            _buildDateSection(),
            const SizedBox(height: 16),
            _buildMemoField(),
            const SizedBox(height: 16),
            _buildMapSelectionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTripNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: '旅行名',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDateSection() {
    return Column(
      children: [
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
      ],
    );
  }

  Widget _buildMemoField() {
    return TextFormField(
      controller: _memoController,
      decoration: const InputDecoration(
        labelText: 'メモ',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildMapSelectionButton() {
    return ElevatedButton(
      onPressed: _toggleMapExpansion,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      child: const Text('訪問場所を地図で選択'),
    );
  }

  Widget _buildMapExpandedLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMapHeader(),
        const SizedBox(height: 20),
        Expanded(child: _buildMapView()),
      ],
    );
  }

  Widget _buildMapHeader() {
    return Row(
      children: [
        const Text(
          '地図で場所を選択',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        IconButton(
          key: _mapIconKey,
          onPressed: _toggleMapExpansion,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildMapView() {
    return widget.isTestEnvironment
        ? _buildTestMapView()
        : _buildProductionMapView();
  }

  Widget _buildTestMapView() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: MapViewFactory.create(
          MapViewType.placeholder,
        ).createMapView(pins: []),
      ),
    );
  }

  Widget _buildProductionMapView() {
    return MapViewFactory.create(MapViewType.google).createMapView(
      pins: _pins,
      onMapLongTapped: _onMapLongTapped,
      onMarkerTapped: _onPinTapped,
      onMarkerUpdated: _onPinUpdated,
      onMarkerDeleted: _onPinDeleted,
      selectedPin: _selectedPin,
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

            if (widget.year != null && _startDate!.year != widget.year!) {
              setState(() {
                _dateErrorMessage = '開始日は${widget.year}年の日付を選択してください';
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

              widget.onSave(tripEntry, pins: _pins);
              Navigator.of(context).pop();
            }
          },
          child: Text(isEditing ? '更新' : '作成'),
        ),
      ],
    );
  }

  DateTime _determineInitialDate(DateTime? selectedDate, String labelText) {
    if (selectedDate != null) {
      return selectedDate;
    }

    if (labelText == '旅行期間 To' && _startDate != null) {
      return DateTime(_startDate!.year, _startDate!.month, 1);
    }

    if (widget.year != null && widget.year != DateTime.now().year) {
      return DateTime(widget.year!, 1, 1);
    }

    return DateTime.now();
  }

  Widget _buildDatePickerField({
    required String labelText,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
  }) {
    return InkWell(
      onTap: () async {
        DateTime initialDate;

        initialDate = _determineInitialDate(selectedDate, labelText);

        final date = await DatePickerUtils.showCustomDatePicker(
          context,
          initialDate: initialDate,
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
