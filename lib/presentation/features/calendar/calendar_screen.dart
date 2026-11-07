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
import 'package:memora/presentation/features/calendar/calendar_labels_dialog.dart';
import 'package:memora/presentation/features/calendar/calendar_day_events_sheet.dart';
import 'package:memora/presentation/features/calendar/calendar_month_grid.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifier.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.onBack,
    this.initialDate,
    this.createEvent = false,
    this.initialRequest = 0,
    this.initialEventId,
    this.initialOccurrence,
  });
  final String groupId;
  final String groupName;
  final VoidCallback onBack;
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
        calendarNotifierProvider(widget.groupId).notifier,
      );
      if (widget.initialDate != null) {
        notifier.selectDate(widget.initialDate!);
      }
      _pendingInitialCreate = widget.createEvent;
      _pendingInitialEventId = widget.initialEventId;
      _loadingInitialExternal = true;
      unawaited(notifier.load());
      unawaited(_loadExternal());
    });
  }

  Future<void> _loadExternal() async {
    final version = _initialRequestVersion;
    try {
      if (!ref.read(externalCalendarSupportedProvider)) return;
      final external = ref.read(externalCalendarNotifierProvider.notifier);
      final date = ref
          .read(calendarNotifierProvider(widget.groupId))
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
    final provider = calendarNotifierProvider(widget.groupId);
    final month = ref.read(provider).month;
    if ((offset < 0 && month.year == 1 && month.month == 1) ||
        (offset > 0 && month.year == 9999 && month.month == 12)) {
      return;
    }
    ref
        .read(provider.notifier)
        .selectDate(DateTime(month.year, month.month + offset));
  }

  Future<void> _selectMonth() async {
    final provider = calendarNotifierProvider(widget.groupId);
    final month = await showDialog<DateTime>(
      context: context,
      builder: (_) => CalendarMonthPickerDialog(month: ref.read(provider).month),
    );
    if (!mounted || month == null) return;
    ref.read(provider.notifier).selectDate(month);
  }

  Future<void> _edit([CalendarEventDto? event]) async {
    final provider = calendarNotifierProvider(widget.groupId);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => CalendarEventDialog(
        groupId: widget.groupId,
        date: ref.read(provider).selectedDate,
        event: event,
      ),
    );
  }

  Future<void> _selectDay(DateTime date) async {
    final provider = calendarNotifierProvider(widget.groupId);
    final state = ref.read(provider);
    if (state.selectedDate != date) {
      ref.read(provider.notifier).selectDate(date);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => CalendarDayEventsSheet(
        groupId: widget.groupId,
        date: date,
        onEdit: (event) => _edit(event),
        onAdd: () => _edit(),
      ),
    );
  }

  void _openInitialRequest() {
    final next = ref.read(calendarNotifierProvider(widget.groupId));
    if ((!_pendingInitialCreate && _pendingInitialEventId == null) ||
        next.isLoading ||
        next.isSaving ||
        next.loadError.isNotEmpty ||
        !next.hasLoadedLabels ||
        next.group == null) {
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
    final provider = calendarNotifierProvider(widget.groupId);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final externalSupported = ref.watch(externalCalendarSupportedProvider);
    final external = externalSupported
        ? ref.watch(externalCalendarNotifierProvider)
        : null;
    final displayState = external == null
        ? state
        : overlayExternalCalendar(state, external);
    ref.listen(provider.select((value) => value.month), (_, month) {
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
    final month = state.month;
    final canEdit =
        !state.isSaving && !state.isLoading && state.loadError.isEmpty;
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
                      IconButton(
                        tooltip: 'グループ選択へ戻る',
                        onPressed: state.isSaving ? null : widget.onBack,
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Expanded(
                        child: Text(
                          '${widget.groupName}のカレンダー',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
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
                        tooltip: '色ラベルの設定',
                        onPressed: canEdit
                            ? () => showDialog<void>(
                                context: context,
                                builder: (context) => CalendarLabelsDialog(
                                  groupId: widget.groupId,
                                ),
                              )
                            : null,
                        icon: const Icon(Icons.palette_outlined),
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
                      IconButton(
                        tooltip: '次の月',
                        onPressed: month.year == 9999 && month.month == 12
                            ? null
                            : () => _moveMonth(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
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
                      for (final day in const [
                        '日',
                        '月',
                        '火',
                        '水',
                        '木',
                        '金',
                        '土',
                      ])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Center(child: Text(day)),
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: CalendarMonthGrid(
                      state: displayState,
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
