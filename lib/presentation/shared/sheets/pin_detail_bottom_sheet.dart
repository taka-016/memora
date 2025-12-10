import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/domain/services/nearby_location_service.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/infrastructure/services/google_places_api_nearby_location_service.dart';
import 'package:memora/env/env.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/helpers/date_picker_helper.dart';

class PinDetailBottomSheet extends HookWidget {
  final PinDto pin;
  final VoidCallback onClose;
  final Function(PinDto pin)? onUpdate;
  final Function(String)? onDelete;
  final NearbyLocationService? reverseGeocodingService;

  const PinDetailBottomSheet({
    super.key,
    required this.pin,
    required this.onClose,
    this.onUpdate,
    this.onDelete,
    this.reverseGeocodingService,
  });

  @override
  Widget build(BuildContext context) {
    final fromDate = useState<DateTime?>(null);
    final fromTime = useState<TimeOfDay?>(null);
    final toDate = useState<DateTime?>(null);
    final toTime = useState<TimeOfDay?>(null);
    final memoController = useTextEditingController();
    final dateErrorMessage = useState<String?>(null);
    final locationName = useState<String?>(null);
    final isLoadingLocation = useState(false);
    final effectiveReverseGeocodingService = useMemoized(
      () =>
          reverseGeocodingService ??
          GooglePlacesApiNearbyLocationService(apiKey: Env.googlePlacesApiKey),
      [reverseGeocodingService],
    );
    final isReadOnly = onUpdate == null;

    DateTime? buildFromDateTime() {
      if (fromDate.value == null) return null;
      final time = fromTime.value ?? const TimeOfDay(hour: 0, minute: 0);
      return DateTime(
        fromDate.value!.year,
        fromDate.value!.month,
        fromDate.value!.day,
        time.hour,
        time.minute,
      );
    }

    DateTime? buildToDateTime() {
      if (toDate.value == null) return null;
      final time = toTime.value ?? const TimeOfDay(hour: 0, minute: 0);
      return DateTime(
        toDate.value!.year,
        toDate.value!.month,
        toDate.value!.day,
        time.hour,
        time.minute,
      );
    }

    void initializeFromPin() {
      fromDate.value = null;
      fromTime.value = null;
      toDate.value = null;
      toTime.value = null;
      memoController.clear();

      locationName.value = pin.locationName;

      if (pin.visitStartDate != null) {
        fromDate.value = DateTime(
          pin.visitStartDate!.year,
          pin.visitStartDate!.month,
          pin.visitStartDate!.day,
        );
        fromTime.value = TimeOfDay(
          hour: pin.visitStartDate!.hour,
          minute: pin.visitStartDate!.minute,
        );
      }

      if (pin.visitEndDate != null) {
        toDate.value = DateTime(
          pin.visitEndDate!.year,
          pin.visitEndDate!.month,
          pin.visitEndDate!.day,
        );
        toTime.value = TimeOfDay(
          hour: pin.visitEndDate!.hour,
          minute: pin.visitEndDate!.minute,
        );
      }

      memoController.text = pin.visitMemo ?? '';
    }

    Future<void> loadLocationName({bool forceRefresh = false}) async {
      if (locationName.value != null &&
          locationName.value!.isNotEmpty &&
          !forceRefresh) {
        return;
      }

      isLoadingLocation.value = true;

      try {
        final currentLocation = Location(
          latitude: pin.latitude,
          longitude: pin.longitude,
        );
        final fetchedLocationName = await effectiveReverseGeocodingService
            .getLocationName(currentLocation);
        locationName.value = fetchedLocationName;
      } catch (e, stack) {
        logger.e(
          '_PinDetailBottomSheetState._loadLocationName: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        locationName.value = null;
      } finally {
        isLoadingLocation.value = false;
      }
    }

    Future<void> selectFromDate(BuildContext context) async {
      final picked = await DatePickerHelper.showCustomDatePicker(
        context,
        initialDate: fromDate.value ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        fromDate.value = picked;
        dateErrorMessage.value = null;
      }
    }

    Future<void> selectFromTime(BuildContext context) async {
      final picked = await showTimePicker(
        context: context,
        initialTime: fromTime.value ?? TimeOfDay.now(),
      );
      if (picked != null) {
        fromTime.value = picked;
        dateErrorMessage.value = null;
      }
    }

    Future<void> selectToDate(BuildContext context) async {
      final picked = await DatePickerHelper.showCustomDatePicker(
        context,
        initialDate: toDate.value ?? (fromDate.value ?? DateTime.now()),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        toDate.value = picked;
        dateErrorMessage.value = null;
      }
    }

    Future<void> selectToTime(BuildContext context) async {
      final picked = await showTimePicker(
        context: context,
        initialTime: toTime.value ?? (fromTime.value ?? TimeOfDay.now()),
      );
      if (picked != null) {
        toTime.value = picked;
        dateErrorMessage.value = null;
      }
    }

    String formatDate(DateTime? date) {
      if (date == null) return '日付を選択';
      return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    }

    String formatTime(TimeOfDay? time) {
      if (time == null) return '時間を選択';
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    void handleDelete() {
      onDelete?.call(pin.pinId);
    }

    void handleUpdate() {
      dateErrorMessage.value = null;

      final start = buildFromDateTime();
      final end = buildToDateTime();

      if (start != null && end != null && start.isAfter(end)) {
        dateErrorMessage.value = '訪問開始日時は訪問終了日時より前の日時を選択してください';
        return;
      }

      if (onUpdate != null) {
        final updatedPin = pin.copyWith(
          visitStartDate: start,
          visitEndDate: end,
          visitMemo: memoController.text,
          locationName: locationName.value,
        );
        onUpdate!(updatedPin);
      }
    }

    Widget buildDateTimeField({
      required String value,
      required VoidCallback onTap,
      required IconData icon,
      Key? testKey,
    }) {
      return InkWell(
        key: testKey,
        onTap: isReadOnly ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54),
            borderRadius: BorderRadius.circular(4),
            color: isReadOnly ? Colors.grey[100] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: isReadOnly ? Colors.black54 : Colors.black,
                  fontSize: 16,
                ),
              ),
              Icon(icon, color: isReadOnly ? Colors.grey : Colors.black54),
            ],
          ),
        ),
      );
    }

    Widget buildDateTimeSection() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('訪問開始日'),
          const SizedBox(height: 8),
          buildDateTimeField(
            testKey: const Key('visitStartDateField'),
            value: formatDate(fromDate.value),
            onTap: () => selectFromDate(context),
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: 8),
          buildDateTimeField(
            testKey: const Key('visitStartTimeField'),
            value: formatTime(fromTime.value),
            onTap: () => selectFromTime(context),
            icon: Icons.access_time,
          ),
          const SizedBox(height: 16),
          const Text('訪問終了日'),
          const SizedBox(height: 8),
          buildDateTimeField(
            testKey: const Key('visitEndDateField'),
            value: formatDate(toDate.value),
            onTap: () => selectToDate(context),
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: 8),
          buildDateTimeField(
            testKey: const Key('visitEndTimeField'),
            value: formatTime(toTime.value),
            onTap: () => selectToTime(context),
            icon: Icons.access_time,
          ),
          if (dateErrorMessage.value != null) ...[
            const SizedBox(height: 8),
            Text(
              dateErrorMessage.value!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
        ],
      );
    }

    Widget buildLocationSection() {
      return Container(
        key: const Key('locationNameField'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.location_on, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Expanded(
              child: isLoadingLocation.value
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
                      locationName.value ?? '場所情報を取得できませんでした',
                      style: TextStyle(
                        color: locationName.value != null
                            ? Colors.black87
                            : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
            SizedBox(
              height: 24,
              width: 24,
              child: IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.refresh),
                onPressed: (isLoadingLocation.value || isReadOnly)
                    ? null
                    : () => loadLocationName(forceRefresh: true),
                color: Colors.grey[600],
                iconSize: 20,
              ),
            ),
          ],
        ),
      );
    }

    Widget buildMemoField() {
      return TextFormField(
        key: const Key('visitMemoField'),
        minLines: 4,
        maxLines: null,
        controller: memoController,
        readOnly: isReadOnly,
        decoration: InputDecoration(
          labelText: 'メモ',
          border: const OutlineInputBorder(),
          fillColor: isReadOnly ? Colors.grey[100] : null,
          filled: isReadOnly,
        ),
      );
    }

    Widget buildActionButtons() {
      if (onUpdate == null && onDelete == null) {
        return const SizedBox.shrink();
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (onDelete != null)
            ElevatedButton(onPressed: handleDelete, child: const Text('削除')),
          if (onUpdate != null)
            ElevatedButton(onPressed: handleUpdate, child: const Text('更新')),
        ],
      );
    }

    Widget buildMainContent() {
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
            buildLocationSection(),
            const SizedBox(height: 16),
            buildDateTimeSection(),
            const SizedBox(height: 16),
            buildMemoField(),
            const SizedBox(height: 24),
            buildActionButtons(),
          ],
        ),
      );
    }

    Widget buildCloseButton() {
      return Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, right: 16),
          child: IconButton(icon: const Icon(Icons.close), onPressed: onClose),
        ),
      );
    }

    Widget buildDragHandle() {
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

    Widget buildBottomSheetContent(ScrollController scrollController) {
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
              buildDragHandle(),
              buildCloseButton(),
              buildMainContent(),
            ],
          ),
        ),
      );
    }

    useEffect(() {
      initializeFromPin();
      loadLocationName();
      return null;
    }, [pin]);

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) =>
          buildBottomSheetContent(scrollController),
    );
  }
}
