import 'package:memora/application/models/calendar_display_settings.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_display_settings_notifier.dart';
import 'package:memora/presentation/features/calendar/calendar_date_color.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/presentation/features/calendar/calendar_month_picker_dialog.dart';
import 'package:memora/composition_root/providers/external_calendar_providers.dart';
import 'package:memora/presentation/notifiers/calendar/external_calendar_notifier.dart';
import 'package:memora/presentation/features/calendar/external_calendar_overlay.dart';
import 'package:memora/presentation/features/calendar/external_calendar_widgets.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/presentation/features/calendar/calendar_event_dialog.dart';
import 'package:memora/presentation/notifiers/calendar/multi_group_calendar_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_group_settings_notifier.dart';
import 'package:memora/presentation/features/calendar/calendar_group_selection_dialog.dart';
import 'package:memora/presentation/features/calendar/calendar_day_events_sheet.dart';
import 'package:memora/presentation/features/calendar/calendar_month_grid.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({
    super.key,
    this.groupId,
    this.groupName,
    this.onBack,
    this.initialDate,
    this.createEvent = false,
    this.initialRequest = 0,
    this.initialEventId,
    this.initialOccurrence,
  });
  final String? groupId;
  final String? groupName;
  final VoidCallback? onBack;
  final DateTime? initialDate;
  final bool createEvent;
  final int initialRequest;
  final String? initialEventId;
  final DateTime? initialOccurrence;
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  bool _pendingInitialCreate = false;
  String? _pendingInitialEventId;
  int _initialRequestVersion = 0;
  bool _loadingInitialExternal = false;

  @override
  void initState() {
    super.initState();
    _initializeRequest();
  }

  void _initializeRequest() {
    final version = ++_initialRequestVersion;
    _pendingInitialCreate = false;
    _pendingInitialEventId = null;
    Future.microtask(() {
      if (!mounted || version != _initialRequestVersion) return;
      final notifier = ref.read(
        multiGroupCalendarNotifierProvider.notifier,
      );
      if (widget.initialDate != null) {
        notifier.selectDate(widget.initialDate!);
      }
      _pendingInitialCreate = widget.createEvent;
      _pendingInitialEventId = widget.initialEventId;
      _loadingInitialExternal = true;

      unawaited(_loadExternal());
    });
  }

  Future<void> _loadExternal() async {
    final version = _initialRequestVersion;
    try {
      if (!ref.read(externalCalendarSupportedProvider)) return;
      final external = ref.read(externalCalendarNotifierProvider.notifier);
      final date = ref
          .read(multiGroupCalendarNotifierProvider).calendar
          .selectedDate;
      await external.setPeriod(date);
      if (mounted) await external.initialize();
    } finally {
      if (mounted && version == _initialRequestVersion) {
        _loadingInitialExternal = false;
        _openInitialRequest();
      }
    }
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId ||
        oldWidget.initialDate != widget.initialDate ||
        oldWidget.createEvent != widget.createEvent ||
        oldWidget.initialEventId != widget.initialEventId ||
        oldWidget.initialOccurrence != widget.initialOccurrence ||
        oldWidget.initialRequest != widget.initialRequest) {
      _initializeRequest();
    }
  }

  void _moveMonth(int offset) {
    final provider = multiGroupCalendarNotifierProvider;
    final month = ref.read(provider).calendar.month;
    if ((offset < 0 && month.year == 1 && month.month == 1) ||
        (offset > 0 && month.year == 9999 && month.month == 12)) {
      return;
    }
    ref
        .read(provider.notifier)
        .selectDate(DateTime(month.year, month.month + offset));
  }

  Future<void> _selectMonth() async {
    final provider = multiGroupCalendarNotifierProvider;
    final month = await showDialog<DateTime>(
      context: context,
      builder: (_) =>
          CalendarMonthPickerDialog(month: ref.read(provider).calendar.month),
    );
    if (!mounted || month == null) return;
    ref.read(provider.notifier).selectDate(month);
  }

  Future<void> _edit([CalendarEventDto? event]) async {
    final provider = multiGroupCalendarNotifierProvider;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => CalendarEventDialog(
        date: ref.read(provider).calendar.selectedDate,
        event: event,
      ),
    );
  }

  Future<void> _selectDay(DateTime date) async {
    final provider = multiGroupCalendarNotifierProvider;
    final state = ref.read(provider).calendar;
    if (state.selectedDate != date) {
      ref.read(provider.notifier).selectDate(date);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => CalendarDayEventsSheet(
        date: date,
        onEdit: (event) => _edit(event),
        onAdd: () => _edit(),
      ),
    );
  }

  void _openInitialRequest() {
    final next = ref.read(multiGroupCalendarNotifierProvider).calendar;
    if ((!_pendingInitialCreate && _pendingInitialEventId == null) ||
        next.isLoading ||
        next.isSaving ||
        next.loadError.isNotEmpty) {
      return;
    }
    final eventId = _pendingInitialEventId;
    final deviceRequest = eventId?.startsWith('device:') == true;
    final external =
        deviceRequest && ref.read(externalCalendarSupportedProvider)
        ? ref.read(externalCalendarNotifierProvider)
        : null;
    if (deviceRequest &&
        (_loadingInitialExternal ||
            external?.isLoading == true ||
            external?.isBusy == true)) {
      return;
    }
    final source = external?.events
        .where((event) => 'device:${event.calendarId}:${event.id}' == eventId)
        .firstOrNull;
    _pendingInitialCreate = false;
    final occurrence = widget.initialOccurrence;
    final event = eventId == null
        ? null
        : next.events.where((event) {
            return event.id == eventId &&
                (widget.groupId == null || event.groupId == widget.groupId) &&
                (event.originalStartDateTime == null ||
                    occurrence == null ||
                    event.originalStartDateTime!.isAtSameMomentAs(occurrence));
          }).firstOrNull;
    _pendingInitialEventId = null;
    final version = _initialRequestVersion;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || version != _initialRequestVersion) return;
      if (eventId != null && event == null && source == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('指定された予定が見つかりませんでした')));
        return;
      }
      if (source != null) {
        final display = overlayExternalCalendar(next, external!);
        final labelId = display.events
            .firstWhere((event) => event.id == externalEventDisplayId(source))
            .labelId;
        final label = display.labels.firstWhere((label) => label.id == labelId);
        unawaited(
          showExternalCalendarEvent(context, source, sourceLabel: label.name),
        );
      } else {
        unawaited(_edit(event));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = multiGroupCalendarNotifierProvider;
    final state = ref.watch(provider).calendar;
    final notifier = ref.read(provider.notifier);
    final externalSupported = ref.watch(externalCalendarSupportedProvider);
    final external = externalSupported
        ? ref.watch(externalCalendarNotifierProvider)
        : null;
    final displayState = external == null
        ? state
        : overlayExternalCalendar(state, external);
    ref.listen(provider.select((value) => value.calendar.month), (_, month) {
      if (externalSupported) {
        unawaited(
          ref.read(externalCalendarNotifierProvider.notifier).setPeriod(month),
        );
      }
    });
    ref.listen(provider, (_, _) => _openInitialRequest());
    if (externalSupported) {
      ref.listen(
        externalCalendarNotifierProvider,
        (_, _) => _openInitialRequest(),
      );
    }
    final settings =
        ref.watch(calendarDisplaySettingsNotifierProvider).value?.settings ??
        const CalendarDisplaySettings();
    final month = state.month;
    final canEdit = !state.isSaving;
    final groupSettings = ref.watch(calendarGroupSettingsNotifierProvider);
    return PopScope(
      canPop: !state.isSaving,
      child: SafeArea(
        child: Stack(
          key: const Key('calendar_screen'),
          children: [
            Positioned.fill(
              bottom: 48,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('カレンダー', style: Theme.of(context).textTheme.titleMedium)),
                      if (!state.isWatching)
                        IconButton(
                          tooltip: '再読み込み',
                          onPressed: state.isLoading || state.isSaving
                              ? null
                              : notifier.load,
                          icon: const Icon(Icons.refresh),
                        ),
                      if (externalSupported)
                        IconButton(
                          tooltip: '端末カレンダー連携',
                          icon: const Icon(Icons.calendar_month_outlined),
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) =>
                                const ExternalCalendarSettingsDialog(),
                          ),
                        ),
                      IconButton(
                        tooltip: '表示グループの選択',
                        onPressed: () => showDialog<void>(context: context, builder: (_) => const CalendarGroupSelectionDialog()),
                        icon: const Icon(Icons.groups_outlined),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: '前の月',
                        onPressed: month.year == 1 && month.month == 1
                            ? null
                            : () => _moveMonth(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      TextButton(
                        onPressed: () => notifier.selectDate(
                          ref.read(appClockProvider).now(),
                        ),
                        child: const Text('今日'),
                      ),
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: TextButton(
                              onPressed: _selectMonth,
                              child: Text(
                                '${month.year}年${month.month}月',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 64),
                      IconButton(
                        tooltip: '次の月',
                        onPressed: month.year == 9999 && month.month == 12
                            ? null
                            : () => _moveMonth(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  if (groupSettings.effectiveSettings.visibleGroupIds.isEmpty)
                    TextButton(onPressed: () => showDialog<void>(context: context, builder: (_) => const CalendarGroupSelectionDialog()), child: const Text('表示するグループを選択してください')),
                  if (state.isLoading) const LinearProgressIndicator(),
                  if (state.loadError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(child: Text(state.loadError)),
                          TextButton(
                            onPressed: state.isLoading || state.isSaving
                                ? null
                                : notifier.load,
                            child: const Text('再試行'),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      for (final day in settings.weekStart.dayNames)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Center(
                              child: Text(
                                day,
                                style: TextStyle(
                                  color: day == '日'
                                      ? calendarWeekdayColor(
                                          DateTime.sunday,
                                          Theme.of(context).brightness,
                                        )
                                      : day == '土'
                                      ? calendarWeekdayColor(
                                          DateTime.saturday,
                                          Theme.of(context).brightness,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: CalendarMonthGrid(
                      state: displayState,
                      settings: settings,
                      onSelectDay: (date) => _selectDay(date),
                      onMoveMonth: _moveMonth,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                tooltip: '予定を追加',
                shape: const CircleBorder(),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer
                    .withValues(alpha: .85),
                onPressed: canEdit ? () => _edit() : null,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
