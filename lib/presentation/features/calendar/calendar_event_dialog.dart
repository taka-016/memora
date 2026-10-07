import 'package:memora/presentation/helpers/date_picker_helper.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_settings.dart';
import 'package:memora/application/usecases/calendar/change_calendar_recurrence_usecase.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/presentation/features/calendar/calendar_recurrence_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_preferences_notifier.dart';

String calendarDateText(DateTime value) =>
    '${value.year}/${value.month}/${value.day}';
String calendarTimeText(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
String calendarPeriodText(CalendarEventDto event) {
  if (event.isAllDay) {
    return '${calendarDateText(event.startDateTime)} 〜 ${calendarDateText(event.endDateTime)}（終日）';
  }
  final start = event.startDateTime.toLocal();
  final end = event.endDateTime.toLocal();
  return '${calendarDateText(start)} ${calendarTimeText(start)} 〜 ${calendarDateText(end)} ${calendarTimeText(end)}';
}

class CalendarEventDialog extends ConsumerStatefulWidget {
  const CalendarEventDialog({
    super.key,
    required this.groupId,
    required this.date,
    this.event,
  });
  final String groupId;
  final DateTime date;
  final CalendarEventDto? event;

  @override
  ConsumerState<CalendarEventDialog> createState() =>
      _CalendarEventDialogState();
}

class _CalendarEventDialogState extends ConsumerState<CalendarEventDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late DateTime _start;
  late DateTime _end;
  late bool _allDay;
  String? _labelId;
  String _error = '';
  late CalendarRecurrenceSettings _recurrence;
  bool _recurrenceEdited = false;
  late final String _zone;
  bool? _seriesAllDay;

  bool get _hasIndividualChanges => widget.event?.hasIndividualChanges ?? false;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _title = TextEditingController(text: event?.title ?? '');
    _allDay = event?.isAllDay ?? true;
    _start = event == null
        ? widget.date
        : _allDay
        ? DateTime(
            event.startDateTime.year,
            event.startDateTime.month,
            event.startDateTime.day,
          )
        : event.startDateTime.toLocal();
    _end = event == null
        ? widget.date
        : _allDay
        ? DateTime(
            event.endDateTime.year,
            event.endDateTime.month,
            event.endDateTime.day,
          )
        : event.endDateTime.toLocal();
    _seriesAllDay = event == null
        ? null
        : ref
                  .read(calendarNotifierProvider(widget.groupId).notifier)
                  .seriesForEvent(event.id)
                  ?.isAllDay ??
              event.isAllDay;
    _zone = event?.timeZone ?? 'Asia/Tokyo';
    final expander = ref.read(calendarRecurrenceExpanderProvider);
    if (event != null && !event.isAllDay && event.timeZone != null) {
      final start = expander.localTime(event.startDateTime, _zone);
      final end = expander.localTime(event.endDateTime, _zone);
      _start = DateTime(
        start.year,
        start.month,
        start.day,
        start.hour,
        start.minute,
        start.second,
      );
      _end = DateTime(
        end.year,
        end.month,
        end.day,
        end.hour,
        end.minute,
        end.second,
      );
    }
    _recurrence = CalendarRecurrenceSettings.fromRule(
      event?.recurrenceRule,
      _start,
      zone: event?.timeZone,
      expander: expander,
    );
    _labelId =
        event?.labelId ??
        ref
            .read(calendarNotifierProvider(widget.groupId))
            .labels
            .firstOrNull
            ?.id;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start, bool time) async {
    final current = start ? _start : _end;
    DateTime? result;
    if (time) {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(current),
        helpText: start ? '開始時刻' : '終了時刻',
        cancelText: 'キャンセル',
        confirmText: '決定',
      );
      if (picked != null) {
        result = DateTime(
          current.year,
          current.month,
          current.day,
          picked.hour,
          picked.minute,
        );
      }
    } else {
      final picked = await DatePickerHelper.showCustomDatePicker(
        context,
        initialDate: DateTime(current.year, current.month, current.day),
        firstDate: DateTime(1),
        lastDate: DateTime(9999, 12, 31),
      );
      if (picked != null) {
        result = DateTime(
          picked.year,
          picked.month,
          picked.day,
          current.hour,
          current.minute,
        );
      }
    }
    if (!mounted || result == null) return;
    setState(() {
      if (start) {
        if (!time) {
          _end = _end.add(result!.difference(_start));
          if (!_hasIndividualChanges && _recurrence.frequency != null) {
            _recurrence = _recurrence.alignedTo(result!, previous: _start);
            _recurrenceEdited = true;
          }
        }
        _start = result!;
        if (time) {
          final minutes = ref
              .read(calendarPreferencesNotifierProvider)
              .value!
              .minutes;
          _end = _start.add(Duration(minutes: minutes));
        }
      } else {
        _end = result!;
      }
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!_hasIndividualChanges &&
        _recurrence.until != null &&
        DateTime(
          _recurrence.until!.year,
          _recurrence.until!.month,
          _recurrence.until!.day,
        ).isBefore(DateTime(_start.year, _start.month, _start.day))) {
      setState(() => _error = '繰り返しの終了日は開始日以降にしてください');
      return;
    }
    final recurring = widget.event?.originalStartDateTime != null;
    final scope = recurring ? await _chooseScope(false) : null;
    if (!mounted || recurring && scope == null) return;
    bool success;
    try {
      final expander = ref.read(calendarRecurrenceExpanderProvider);
      final original = widget.event?.originalStartDateTime;
      final series = recurring
          ? ref
                .read(calendarNotifierProvider(widget.groupId).notifier)
                .seriesForEvent(widget.event!.id)
          : null;
      final recurrenceStart = recurring && !_recurrenceEdited
          ? _seriesAllDay == true
                ? DateTime.utc(original!.year, original.month, original.day)
                : expander.localTime(original!, series?.timeZone ?? _zone)
          : _start;
      final rule =
          scope == CalendarChangeScope.only ||
              (!_recurrenceEdited && _allDay == _seriesAllDay)
          ? widget.event?.recurrenceRule
          : _recurrence.toRule(
              start: recurrenceStart,
              allDay: _allDay,
              zone: _zone,
              expander: expander,
            );
      final inputZone = rule != null ? _zone : widget.event?.timeZone;
      final start = _allDay
          ? DateTime(_start.year, _start.month, _start.day)
          : inputZone != null
          ? expander.resolveTime(_start, inputZone)
          : _start;
      final end = _allDay
          ? DateTime(_end.year, _end.month, _end.day)
          : inputZone != null
          ? expander.resolveTime(_end, inputZone)
          : _end;
      if (end.isBefore(start)) {
        setState(() => _error = '終了日時は開始日時以降にしてください');
        return;
      }
      final input = CalendarEventDto(
        id: widget.event?.id ?? '',
        groupId: widget.groupId,
        labelId: _labelId!,
        title: _title.text.trim(),
        startDateTime: start,
        endDateTime: end,
        isAllDay: _allDay,
        recurrenceRule: rule,
        timeZone: rule != null && !_allDay ? _zone : null,
      );
      final notifier = ref.read(
        calendarNotifierProvider(widget.groupId).notifier,
      );
      success = recurring
          ? await notifier.changeRecurringEvent(
              widget.event!,
              scope!,
              changes: input,
            )
          : await notifier.saveEvent(input);
    } on ApplicationValidationException catch (e) {
      if (mounted) setState(() => _error = e.message);
      return;
    }
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(
        () => _error = ref
            .read(calendarNotifierProvider(widget.groupId))
            .mutationError,
      );
    }
  }

  Future<CalendarChangeScope?> _chooseScope(bool deleting) async {
    var scope = CalendarChangeScope.only;
    return showDialog<CalendarChangeScope>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) {
          final impact = ref
              .read(calendarNotifierProvider(widget.groupId).notifier)
              .recurrenceImpact(widget.event!, scope);
          return AlertDialog(
            title: Text(deleting ? '予定を削除' : '予定の変更範囲'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RadioGroup<CalendarChangeScope>(
                    groupValue: scope,
                    onChanged: (value) => update(() => scope = value!),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final entry in {
                          CalendarChangeScope.only: 'この予定のみ',
                          if (!_hasIndividualChanges)
                            CalendarChangeScope.following: 'この予定とこれ以降',
                          if (!_hasIndividualChanges)
                            CalendarChangeScope.all: 'すべての予定',
                        }.entries)
                          RadioListTile<CalendarChangeScope>(
                            value: entry.key,
                            title: Text(entry.value),
                          ),
                      ],
                    ),
                  ),
                  if (scope == CalendarChangeScope.only)
                    const Text('この回だけを変更します。系列の繰り返し設定は変更しません。'),
                  if (scope == CalendarChangeScope.following)
                    const Text('元の開始日時を境に系列を分割します。対象範囲外の回は変更しません。'),
                  if (scope != CalendarChangeScope.only)
                    Text(
                      deleting
                          ? '対象範囲の個別変更した予定${impact.reset}件も削除します。移動済みの予定も元の予定日時を基準に削除します。対象範囲外の個別変更は維持します。'
                          : '個別変更した予定はそのまま維持します。日時・タイトル・色ラベル・終日区分の個別変更と個別の取消しは変更しません。',
                    ),
                  if (deleting && scope == CalendarChangeScope.only)
                    const Text('この回の取消しを保存します。'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, scope),
                child: Text(deleting ? '削除する' : '変更する'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _resetOverride() async {
    final notifier = ref.read(
      calendarNotifierProvider(widget.groupId).notifier,
    );
    final original = notifier.originalOccurrenceForEvent(widget.event!);
    if (notifier.seriesForEvent(widget.event!.id) == null) {
      setState(() => _error = '元の予定が見つかりません。再読み込みしてください');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('個別変更をリセット'),
        content: Text(
          original == null
              ? '現在の繰り返し条件に対応する回がないため、リセットするとこの個別予定は削除されます。'
              : '日時・タイトル・色ラベル・終日区分の個別変更をすべて取り消し、現在の繰り返し予定に戻します。\n\n${original.title}\n${calendarPeriodText(original)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('リセットする'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await notifier.resetRecurringEvent(widget.event!);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(
        () => _error = ref
            .read(calendarNotifierProvider(widget.groupId))
            .mutationError,
      );
    }
  }

  Future<void> _delete() async {
    if (widget.event!.originalStartDateTime != null) {
      final scope = await _chooseScope(true);
      if (!mounted || scope == null) return;
      final success = await ref
          .read(calendarNotifierProvider(widget.groupId).notifier)
          .changeRecurringEvent(widget.event!, scope);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
      } else {
        setState(
          () => _error = ref
              .read(calendarNotifierProvider(widget.groupId))
              .mutationError,
        );
      }
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('予定を削除'),
        content: const Text('この予定を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await ref
        .read(calendarNotifierProvider(widget.groupId).notifier)
        .deleteEvent(widget.event!.id);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(
        () => _error = ref
            .read(calendarNotifierProvider(widget.groupId))
            .mutationError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarNotifierProvider(widget.groupId));
    final labels = state.labels;
    final preferences = ref.watch(calendarPreferencesNotifierProvider);
    final dateInputStyle = TextButton.styleFrom(
      alignment: Alignment.centerLeft,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
    );
    return PopScope(
      canPop: !state.isSaving,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Material(
          type: MaterialType.card,
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.95,
            height: MediaQuery.sizeOf(context).height * 0.8,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.event == null ? '予定を追加' : '予定を編集',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _form,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 16,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _title,
                              enabled: !state.isSaving,
                              decoration: const InputDecoration(
                                labelText: 'タイトル',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'タイトルを入力してください'
                                  : null,
                            ),
                            DropdownButtonFormField<String>(
                              initialValue:
                                  labels.any((label) => label.id == _labelId)
                                  ? _labelId
                                  : null,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: '色ラベル',
                                border: OutlineInputBorder(),
                              ),
                              items: labels
                                  .map(
                                    (label) => DropdownMenuItem(
                                      value: label.id,
                                      child: Text(
                                        label.name,
                                        overflow: TextOverflow.clip,
                                        softWrap: false,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: state.isSaving
                                  ? null
                                  : (value) => setState(() => _labelId = value),
                              validator: (value) =>
                                  value == null ? '色ラベルを指定してください' : null,
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('終日'),
                              value: _allDay,
                              onChanged: state.isSaving
                                  ? null
                                  : (value) => setState(() => _allDay = value),
                            ),
                            for (final start in [true, false])
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextButton(
                                      style: dateInputStyle,
                                      onPressed: state.isSaving
                                          ? null
                                          : () => _pick(start, false),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${start ? '開始' : '終了'}日: ${calendarDateText(start ? _start : _end)}',
                                            ),
                                          ),
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (!_allDay)
                                    Expanded(
                                      flex: 2,
                                      child: TextButton(
                                        style: dateInputStyle,
                                        key: Key(
                                          'calendar_${start ? 'start' : 'end'}_time',
                                        ),
                                        onPressed:
                                            state.isSaving ||
                                                (start &&
                                                    preferences.value == null)
                                            ? null
                                            : () => _pick(start, true),
                                        child: Text(
                                          calendarTimeText(
                                            start ? _start : _end,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('繰り返し'),
                              enabled: !_hasIndividualChanges,
                              subtitle: Text(
                                _hasIndividualChanges
                                    ? '${_recurrence.summary}\n個別変更した予定です。繰り返しに戻すには個別変更をリセットしてください。'
                                    : _recurrence.summary,
                              ),
                              trailing: _hasIndividualChanges
                                  ? null
                                  : const Icon(Icons.chevron_right),
                              onTap: state.isSaving || _hasIndividualChanges
                                  ? null
                                  : () async {
                                      final value =
                                          await showCalendarRecurrencePicker(
                                            context,
                                            _recurrence,
                                            _start,
                                          );
                                      if (value != null && mounted) {
                                        setState(() {
                                          _recurrence = value;
                                          _recurrenceEdited = true;
                                        });
                                      }
                                    },
                            ),
                            if (!_allDay && preferences.hasError)
                              TextButton(
                                onPressed: () => ref.invalidate(
                                  calendarPreferencesNotifierProvider,
                                ),
                                child: const Text('標準時間を再取得'),
                              ),
                            if (_hasIndividualChanges)
                              TextButton(
                                onPressed: state.isSaving
                                    ? null
                                    : _resetOverride,
                                child: const Text('個別変更をリセット'),
                              ),
                            if (_error.isNotEmpty)
                              Text(
                                _error,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    spacing: 8,
                    overflowSpacing: 8,
                    children: [
                      if (widget.event != null)
                        TextButton(
                          onPressed: state.isSaving ? null : _delete,
                          child: const Text('削除'),
                        ),
                      TextButton(
                        onPressed: state.isSaving
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('キャンセル'),
                      ),
                      ElevatedButton(
                        onPressed: state.isSaving ? null : _save,
                        child: Text(state.isSaving ? '保存中' : '保存'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
