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
  late String _zone;

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
      final picked = await showDatePicker(
        context: context,
        initialDate: current,
        firstDate: DateTime(1),
        lastDate: DateTime(9999, 12, 31),
        helpText: start ? '開始日' : '終了日',
        cancelText: 'キャンセル',
        confirmText: '決定',
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
    final recurring = widget.event?.originalStartDateTime != null;
    final scope = recurring ? await _chooseScope(false) : null;
    if (!mounted || recurring && scope == null) return;
    bool success;
    try {
      final expander = ref.read(calendarRecurrenceExpanderProvider);
      final rule =
          scope == CalendarChangeScope.only ||
              (!_recurrenceEdited && _allDay == widget.event?.isAllDay)
          ? widget.event?.recurrenceRule
          : _recurrence.toRule(
              start: _start,
              allDay: _allDay,
              zone: _zone,
              expander: expander,
            );
      final inputZone = rule != null ? _zone : widget.event?.timeZone;
      final start = _allDay
          ? DateTime.utc(_start.year, _start.month, _start.day)
          : inputZone != null
          ? expander.resolveTime(_start, inputZone)
          : _start;
      final end = _allDay
          ? DateTime.utc(_end.year, _end.month, _end.day)
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
                          CalendarChangeScope.following: 'この予定とこれ以降',
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
                      '対象範囲の個別回の上書き（移動・取消しを含む）${impact.reset}件を解除します。対象範囲外の${impact.retained}件は引き継ぎます。',
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
    return PopScope(
      canPop: !state.isSaving,
      child: AlertDialog(
        title: Text(widget.event == null ? '予定を追加' : '予定を編集'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _title,
                    enabled: !state.isSaving,
                    decoration: const InputDecoration(labelText: 'タイトル'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'タイトルを入力してください'
                        : null,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: labels.any((label) => label.id == _labelId)
                        ? _labelId
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '色ラベル'),
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
                            onPressed: state.isSaving
                                ? null
                                : () => _pick(start, false),
                            child: Text(
                              '${start ? '開始' : '終了'}日: ${calendarDateText(start ? _start : _end)}',
                            ),
                          ),
                        ),
                        if (!_allDay)
                          Expanded(
                            flex: 2,
                            child: TextButton(
                              key: Key(
                                'calendar_${start ? 'start' : 'end'}_time',
                              ),
                              onPressed:
                                  state.isSaving ||
                                      (start && preferences.value == null)
                                  ? null
                                  : () => _pick(start, true),
                              child: Text(
                                calendarTimeText(start ? _start : _end),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('繰り返し'),
                    subtitle: Text(_recurrence.summary),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: state.isSaving
                        ? null
                        : () async {
                            final value = await showCalendarRecurrencePicker(
                              context,
                              _recurrence,
                              _start,
                            );
                            if (value != null && mounted)
                              setState(() {
                                _recurrence = value;
                                _recurrenceEdited = true;
                              });
                          },
                  ),
                  if (!_allDay && _recurrence.frequency != null)
                    TextFormField(
                      initialValue: _zone,
                      enabled: !state.isSaving,
                      decoration: const InputDecoration(
                        labelText: 'タイムゾーン',
                        helperText: 'IANA名（例: Asia/Tokyo）で指定',
                      ),
                      onChanged: (value) => _zone = value.trim(),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'タイムゾーンを指定してください'
                          : null,
                    ),
                  if (!_allDay && preferences.hasError)
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(calendarPreferencesNotifierProvider),
                      child: const Text('標準時間を再取得'),
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
        actions: [
          if (widget.event != null)
            TextButton(
              onPressed: state.isSaving ? null : _delete,
              child: const Text('削除'),
            ),
          TextButton(
            onPressed: state.isSaving ? null : () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: state.isSaving ? null : _save,
            child: Text(state.isSaving ? '保存中' : '保存'),
          ),
        ],
      ),
    );
  }
}
