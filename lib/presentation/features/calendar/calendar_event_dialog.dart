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
    final start = _allDay
        ? DateTime(_start.year, _start.month, _start.day)
        : _start;
    final end = _allDay ? DateTime(_end.year, _end.month, _end.day) : _end;
    if (end.isBefore(start)) {
      setState(() => _error = '終了日時は開始日時以降にしてください');
      return;
    }
    final notifier = ref.read(
      calendarNotifierProvider(widget.groupId).notifier,
    );
    final success = await notifier.saveEvent(
      CalendarEventDto(
        id: widget.event?.id ?? '',
        groupId: widget.groupId,
        labelId: _labelId!,
        title: _title.text.trim(),
        startDateTime: start,
        endDateTime: end,
        isAllDay: _allDay,
      ),
    );
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

  Future<void> _delete() async {
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
