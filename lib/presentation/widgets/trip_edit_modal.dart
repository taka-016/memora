import 'package:flutter/material.dart';
import 'package:memora/domain/value-objects/location.dart';
import '../../domain/entities/trip_entry.dart';
import '../../domain/entities/pin.dart';
import '../../domain/repositories/pin_repository.dart';
import '../../infrastructure/repositories/firestore_pin_repository.dart';
import '../../application/usecases/get_pins_usecase.dart';
import '../../application/usecases/save_pin_usecase.dart';
import '../../application/usecases/delete_pin_usecase.dart';
import '../utils/date_picker_utils.dart';
import '../../infrastructure/factories/map_view_factory.dart';

import 'package:uuid/uuid.dart';

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

  // 地図とピン管理用の変数
  late PinRepository _pinRepository;
  List<Pin> _pins = [];

  @override
  void initState() {
    super.initState();
    if (!widget.isTestEnvironment) {
      _pinRepository = FirestorePinRepository();
    }
    _nameController = TextEditingController(
      text: widget.tripEntry?.tripName ?? '',
    );
    _memoController = TextEditingController(
      text: widget.tripEntry?.tripMemo ?? '',
    );
    _visitLocationController = TextEditingController();
    _startDate = widget.tripEntry?.tripStartDate;
    _endDate = widget.tripEntry?.tripEndDate;
    if (!widget.isTestEnvironment) {
      _loadPins();
    }
  }

  Future<void> _loadPins() async {
    try {
      final getPinsUseCase = GetPinsUseCase(_pinRepository);
      final pins = await getPinsUseCase.execute();
      setState(() {
        _pins = pins;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ピンの読み込みに失敗: $e')));
      }
    }
  }

  Future<void> _onMapTapped(Location location) async {
    if (widget.isTestEnvironment) return;
    final uuid = Uuid();
    final pinId = uuid.v4();
    final newPin = Pin(
      id: pinId,
      pinId: pinId,
      latitude: location.latitude,
      longitude: location.longitude,
    );

    try {
      final savePinUseCase = SavePinUseCase(_pinRepository);
      await savePinUseCase.execute(
        newPin.pinId,
        newPin.latitude,
        newPin.longitude,
      );

      setState(() {
        _pins.add(newPin);
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('マーカーを保存しました')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('マーカー保存に失敗: $e')));
      }
    }
  }

  Future<void> _onMarkerDeleted(String pinId) async {
    if (widget.isTestEnvironment) return;
    try {
      final deletePinUseCase = DeletePinUseCase(_pinRepository);
      await deletePinUseCase.execute(pinId);

      setState(() {
        _pins.removeWhere((pin) => pin.pinId == pinId);
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('マーカーを削除しました')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('マーカー削除に失敗: $e')));
      }
    }
  }

  void _onPinTapped(Pin pin) {
    // ピンタップ時の処理（必要に応じて実装）
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
                  ElevatedButton(
                    onPressed: _toggleMapExpansion,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text('訪問場所を地図で選択'),
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
              icon: const Icon(Icons.close),
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
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: MapViewFactory.create(
                      MapViewType.placeholder,
                    ).createMapView(pins: []),
                  ),
                )
              : MapViewFactory.create(MapViewType.google).createMapView(
                  pins: _pins,
                  onMapLongTapped: _onMapTapped,
                  onMarkerTapped: _onPinTapped,
                  onMarkerDeleted: _onMarkerDeleted,
                ),
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

              widget.onSave(tripEntry);
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
