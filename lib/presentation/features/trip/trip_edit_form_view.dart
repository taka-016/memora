import 'package:flutter/material.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/presentation/helpers/date_picker_helper.dart';

class TripEditFormView extends StatelessWidget {
  const TripEditFormView({
    super.key,
    required this.formKey,
    required this.scrollController,
    required this.titleText,
    required this.nameController,
    required this.memoController,
    required this.startDate,
    required this.endDate,
    required this.pins,
    required this.mapButtonKey,
    required this.onStartDateSelected,
    required this.onEndDateSelected,
    required this.onStartDateCleared,
    required this.onEndDateCleared,
    required this.onShowTaskView,
    required this.onToggleMapExpansion,
    required this.onShowRouteInfoView,
    required this.onPinTapped,
    required this.onPinDeleted,
    this.errorMessage,
    this.configuredYear,
    this.canShowRouteInfo = false,
  });

  final GlobalKey<FormState> formKey;
  final ScrollController scrollController;
  final String titleText;
  final TextEditingController nameController;
  final TextEditingController memoController;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<PinDto> pins;
  final Key mapButtonKey;
  final ValueChanged<DateTime> onStartDateSelected;
  final ValueChanged<DateTime> onEndDateSelected;
  final VoidCallback onStartDateCleared;
  final VoidCallback onEndDateCleared;
  final VoidCallback onShowTaskView;
  final VoidCallback onToggleMapExpansion;
  final VoidCallback onShowRouteInfoView;
  final ValueChanged<PinDto> onPinTapped;
  final ValueChanged<String> onPinDeleted;
  final String? errorMessage;
  final int? configuredYear;
  final bool canShowRouteInfo;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('trip_edit_form_view_root'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleText,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMessage != null) ...[
                    _ErrorBanner(message: errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '旅行名',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      _TripDatePickerField(
                        isEndDate: false,
                        labelText: '旅行期間 From',
                        selectedDate: startDate,
                        configuredYear: configuredYear,
                        comparisonStartDate: startDate,
                        onDateSelected: onStartDateSelected,
                        onClear: onStartDateCleared,
                        clearTooltip: '旅行開始日をクリア',
                      ),
                      const SizedBox(height: 16),
                      _TripDatePickerField(
                        isEndDate: true,
                        labelText: '旅行期間 To',
                        selectedDate: endDate,
                        configuredYear: configuredYear,
                        comparisonStartDate: startDate,
                        onDateSelected: onEndDateSelected,
                        onClear: onEndDateCleared,
                        clearTooltip: '旅行終了日をクリア',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: memoController,
                    decoration: const InputDecoration(
                      labelText: 'メモ',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onShowTaskView,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.checklist, size: 20),
                          const SizedBox(width: 4),
                          const Text('タスク管理'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '訪問場所',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton(
                            key: mapButtonKey,
                            onPressed: onToggleMapExpansion,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add_location, size: 20),
                                SizedBox(width: 4),
                                Text('編集'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton(
                            onPressed: canShowRouteInfo
                                ? onShowRouteInfoView
                                : null,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.route, size: 20),
                                SizedBox(width: 4),
                                Text('経路情報'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _TripPinList(
                    pins: pins,
                    onPinTapped: onPinTapped,
                    onPinDeleted: onPinDeleted,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TripDatePickerField extends StatelessWidget {
  const _TripDatePickerField({
    required this.isEndDate,
    required this.labelText,
    required this.selectedDate,
    required this.onDateSelected,
    required this.comparisonStartDate,
    this.configuredYear,
    this.onClear,
    this.clearTooltip,
  });

  final bool isEndDate;
  final String labelText;
  final DateTime? selectedDate;
  final DateTime? comparisonStartDate;
  final int? configuredYear;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback? onClear;
  final String? clearTooltip;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await DatePickerHelper.showCustomDatePicker(
          context,
          initialDate: _determineInitialDate(),
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
          children: [
            Expanded(
              child: Text(
                selectedDate != null
                    ? '${selectedDate!.year}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.day.toString().padLeft(2, '0')}'
                    : labelText,
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedDate != null && onClear != null)
                  Tooltip(
                    message: clearTooltip ?? '日付をクリア',
                    child: IconButton(
                      icon: const Icon(Icons.clear, color: Colors.black54),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                      onPressed: onClear,
                    ),
                  ),
                const Icon(Icons.calendar_today, color: Colors.black54),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DateTime _determineInitialDate() {
    if (selectedDate != null) {
      return selectedDate!;
    }

    if (isEndDate && comparisonStartDate != null) {
      return DateTime(comparisonStartDate!.year, comparisonStartDate!.month, 1);
    }

    if (configuredYear != null) {
      return DateTime(configuredYear!, 1, 1);
    }

    return DateTime.now();
  }
}

class _TripPinList extends StatelessWidget {
  const _TripPinList({
    required this.pins,
    required this.onPinTapped,
    required this.onPinDeleted,
  });

  final List<PinDto> pins;
  final ValueChanged<PinDto> onPinTapped;
  final ValueChanged<String> onPinDeleted;

  @override
  Widget build(BuildContext context) {
    if (pins.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(pins.length, (index) {
          final pin = pins[index];
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
              subtitle: () {
                final subtitleParts = <String>[];
                if (pin.visitStartDate != null && pin.visitEndDate != null) {
                  subtitleParts.add(
                    '${_formatDateTime(pin.visitStartDate!)} - ${_formatDateTime(pin.visitEndDate!)}',
                  );
                } else if (pin.visitStartDate != null) {
                  subtitleParts.add(
                    '開始: ${_formatDateTime(pin.visitStartDate!)}',
                  );
                } else if (pin.visitEndDate != null) {
                  subtitleParts.add(
                    '終了: ${_formatDateTime(pin.visitEndDate!)}',
                  );
                }

                if (subtitleParts.isEmpty) {
                  return null;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: subtitleParts
                      .map(
                        (text) =>
                            Text(text, style: const TextStyle(fontSize: 12)),
                      )
                      .toList(),
                );
              }(),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => onPinDeleted(pin.pinId),
              ),
              onTap: () => onPinTapped(pin),
            ),
          );
        }),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        message,
        style: TextStyle(color: Colors.red.shade700, fontSize: 14),
      ),
    );
  }
}
