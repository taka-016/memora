import 'package:flutter/material.dart';
import 'package:memora/application/dtos/pin/pin_dto.dart';
import 'package:memora/application/mappers/pin_mapper.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/presentation/helpers/date_picker_helper.dart';
import 'package:memora/presentation/shared/map_views/map_view_factory.dart';
import 'package:memora/presentation/shared/sheets/pin_detail_bottom_sheet.dart';
import 'package:uuid/uuid.dart';
import 'package:memora/core/app_logger.dart';

class TripEditModal extends StatefulWidget {
  final String groupId;
  final TripEntry? tripEntry;
  final List<PinDto>? pins;
  final Function(TripEntry) onSave;
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
  String? _errorMessage;
  bool _isMapExpanded = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _mapIconKey = GlobalKey();

  List<PinDto> _pins = [];
  PinDto? _selectedPin;
  bool _isBottomSheetVisible = false;

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
    final newPin = PinDto(
      pinId: pinId,
      latitude: location.latitude,
      longitude: location.longitude,
    );

    setState(() {
      _pins.add(newPin);
      _selectedPin = newPin;
    });
  }

  void _onPinTapped(PinDto pin) {
    setState(() {
      _selectedPin = pin;
    });
  }

  void _hidePinDetailBottomSheet() {
    setState(() {
      _isBottomSheetVisible = false;
      _selectedPin = null;
    });
  }

  Future<void> _onPinDeleted(String pinId) async {
    setState(() {
      _pins.removeWhere((pin) => pin.pinId == pinId);
      if (_selectedPin?.pinId == pinId) {
        _selectedPin = null;
      }
    });
    _hidePinDetailBottomSheet();
  }

  void _onPinUpdated(PinDto pin) {
    setState(() {
      final index = _pins.indexWhere((p) => p.pinId == pin.pinId);
      if (index != -1) {
        _pins[index] = pin;
      }
    });
    _hidePinDetailBottomSheet();
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
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(child: _buildForm()),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
        _buildBottomSheet(),
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
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildTripNameField(),
            const SizedBox(height: 16),
            _buildDateSection(),
            const SizedBox(height: 16),
            _buildMemoField(),
            const SizedBox(height: 16),
            _buildPinsTitle(),
            const SizedBox(height: 8),
            _buildMapButton(),
            const SizedBox(height: 16),
            _buildPinsList(),
            const SizedBox(height: 16),
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
              _errorMessage = null;
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
              _errorMessage = null;
            });
          },
        ),
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

  Widget _buildPinsTitle() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '訪問場所',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildMapButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: _toggleMapExpansion,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
        child: const Text('地図で選択'),
      ),
    );
  }

  Widget _buildPinsList() {
    if (_pins.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(_pins.length, (index) {
          final pin = _pins[index];
          return _buildPinListItem(pin, index);
        }),
      ],
    );
  }

  Widget _buildPinListItem(PinDto pin, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: ListTile(
        key: Key('pinListItem_${pin.pinId}'),
        dense: true,
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
        title: Text(
          pin.locationName?.isNotEmpty == true ? pin.locationName! : '',
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: _buildPinSubtitle(pin),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _onPinDeleted(pin.pinId),
        ),
        onTap: () {
          _onPinTapped(pin);
          setState(() {
            _isBottomSheetVisible = true;
          });
        },
      ),
    );
  }

  Widget? _buildPinSubtitle(PinDto pin) {
    final List<String> subtitleParts = [];

    if (pin.visitStartDate != null && pin.visitEndDate != null) {
      subtitleParts.add(
        '${_formatDateTime(pin.visitStartDate!)} - ${_formatDateTime(pin.visitEndDate!)}',
      );
    } else if (pin.visitStartDate != null) {
      subtitleParts.add('開始: ${_formatDateTime(pin.visitStartDate!)}');
    } else if (pin.visitEndDate != null) {
      subtitleParts.add('終了: ${_formatDateTime(pin.visitEndDate!)}');
    }

    if (subtitleParts.isEmpty) {
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: subtitleParts
          .map((text) => Text(text, style: const TextStyle(fontSize: 12)))
          .toList(),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }

  Widget _buildBottomSheet() {
    if (!_isBottomSheetVisible || _selectedPin == null) {
      return const SizedBox.shrink();
    }

    return PinDetailBottomSheet(
      pin: _selectedPin!,
      onUpdate: _onPinUpdated,
      onDelete: _onPinDeleted,
      onClose: _hidePinDetailBottomSheet,
    );
  }

  Widget _buildMapExpandedLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMapHeader(),
        const SizedBox(height: 20),
        Expanded(
          child: Stack(children: [_buildMapView(), _buildBottomSheet()]),
        ),
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

  Future<void> _handleSave() async {
    setState(() {
      _errorMessage = null;
    });

    if (_startDate == null || _endDate == null) {
      setState(() {
        _errorMessage = '開始日と終了日を選択してください';
      });
      return;
    }

    if (_startDate!.isAfter(_endDate!)) {
      setState(() {
        _errorMessage = '開始日は終了日より前の日付を選択してください';
      });
      return;
    }

    if (widget.year != null && _startDate!.year != widget.year!) {
      setState(() {
        _errorMessage = '開始日は${widget.year}年の日付を選択してください';
      });
      return;
    }

    if (_formKey.currentState!.validate()) {
      try {
        final tripEntry = TripEntry(
          id: widget.tripEntry?.id ?? '',
          groupId: widget.groupId,
          tripName: _nameController.text.isEmpty ? null : _nameController.text,
          tripStartDate: _startDate!,
          tripEndDate: _endDate!,
          tripMemo: _memoController.text.isEmpty ? null : _memoController.text,
          pins: PinMapper.toEntityList(_pins),
        );

        widget.onSave(tripEntry);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } on ValidationException catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = '$e';
          });
        }
      } catch (e, stack) {
        logger.e(
          '_TripEditModalState._handleSave: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        if (mounted) {
          setState(() {
            _errorMessage = 'エラーが発生しました: $e';
          });
        }
      }
    }
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
          onPressed: _handleSave,
          child: Text(isEditing ? '更新' : '作成'),
        ),
      ],
    );
  }

  @visibleForTesting
  void setDateRangeForTest(DateTime? start, DateTime? end) {
    setState(() {
      _startDate = start;
      _endDate = end;
    });
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

        final date = await DatePickerHelper.showCustomDatePicker(
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
