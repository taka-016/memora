import 'package:memora/composition_root/providers/url_launcher_provider.dart';
import 'package:memora/presentation/features/calendar/calendar_location_field.dart';
import 'package:memora/presentation/shared/dialogs/edit_discard_scope.dart';
import 'package:memora/presentation/features/calendar/calendar_notification_editor.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notification_preferences_notifier.dart';
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
    final lastDay = DateTime.utc(
      event.endDateTime.year,
      event.endDateTime.month,
      event.endDateTime.day - 1,
    );
    return '${calendarDateText(event.startDateTime)} 〜 ${calendarDateText(lastDay)}（終日）';
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
  late final TextEditingController _url;
  late final TextEditingController _memo;
  late final TextEditingController _locationName;
  double? _latitude;
  double? _longitude;
  late DateTime _start;
  late DateTime _end;
  late bool _allDay;
  String? _labelId;
  String _error = '';
  List<int>? _notifications;
  late CalendarRecurrenceSettings _recurrence;
  bool _recurrenceEdited = false;
  late final String _zone;
  bool? _seriesAllDay;
  CalendarEventDto? _seriesAtOpen;
  late final Object _initialValues;
  List<int>? _initialNotifications;

  Object get _editValues => (
    _title.text,
    _url.text,
    _memo.text,
    _locationName.text,
    _latitude,
    _longitude,
    _start,
    _end,
    _allDay,
    _labelId,
    _recurrence.frequency,
    _recurrence.interval,
    (_recurrence.weekdays.toList()..sort()).join(','),
    _recurrence.monthDay,
    _recurrence.ordinal,
    _recurrence.count,
    _recurrence.until == null
        ? null
        : DateTime(
            _recurrence.until!.year,
            _recurrence.until!.month,
            _recurrence.until!.day,
          ),
  );

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _seriesAtOpen = event == null
        ? null
        : ref
              .read(calendarNotifierProvider(widget.groupId).notifier)
              .seriesForEvent(event.id);
    _notifications = event?.notificationMinutesBefore;
    _initialNotifications = _notifications == null
        ? null
        : List.of(_notifications!);
    _title = TextEditingController(text: event?.title ?? '');
    _url = TextEditingController(text: event?.url ?? '');
    _memo = TextEditingController(text: event?.memo ?? '');
    _locationName = TextEditingController(text: event?.locationName ?? '');
    _latitude = event?.latitude;
    _longitude = event?.longitude;
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
            event.endDateTime.day - 1,
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
        event?.labelKey ??
        ref
            .read(calendarNotifierProvider(widget.groupId))
            .displayLabels
            .firstOrNull
            ?.id;
    _initialValues = _editValues;
  }

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    _memo.dispose();
    _locationName.dispose();
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
    final next = result;
    setState(() {
      if (start) {
        if (!time) {
          _end = _end.add(next.difference(_start));
          if (_recurrence.frequency != null &&
              (next.year != _start.year ||
                  next.month != _start.month ||
                  next.day != _start.day)) {
            _recurrence = _recurrence.alignedTo(next, previous: _start);
            _recurrenceEdited = true;
          }
        }
        _start = next;
        if (time) {
          final minutes = ref
              .read(calendarPreferencesNotifierProvider)
              .value!
              .minutes;
          _end = _start.add(Duration(minutes: minutes));
        }
      } else {
        _end = next;
      }
    });
  }

  Future<void> _openUrl() async {
    final uri = Uri.tryParse(_url.text.trim());
    if (uri == null ||
        !['https', 'http'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      setState(() => _error = 'httpまたはhttpsのURLを入力してください');
      return;
    }
    setState(() => _error = '');
    try {
      final opened = await ref.read(openUrlProvider)(uri);
      if (!opened && mounted) setState(() => _error = 'URLを開けませんでした');
    } catch (_) {
      if (mounted) setState(() => _error = 'URLを開けませんでした');
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final recurring = widget.event?.originalStartDateTime != null;
    final scope = recurring ? await _chooseScope(false) : null;
    if (!mounted || recurring && scope == null) return;
    if (scope != CalendarChangeScope.only &&
        _recurrence.until != null &&
        DateTime(
          _recurrence.until!.year,
          _recurrence.until!.month,
          _recurrence.until!.day,
        ).isBefore(DateTime(_start.year, _start.month, _start.day))) {
      setState(() => _error = '繰り返しの終了日は開始日以降にしてください');
      return;
    }
    bool success;
    try {
      final expander = ref.read(calendarRecurrenceExpanderProvider);
      final original = widget.event?.originalStartDateTime;
      final series = recurring ? _seriesAtOpen : null;
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
          ? DateTime.utc(_start.year, _start.month, _start.day)
          : inputZone != null
          ? expander.resolveTime(_start, inputZone)
          : _start;
      final end = _allDay
          ? DateTime.utc(_end.year, _end.month, _end.day + 1)
          : inputZone != null
          ? expander.resolveTime(_end, inputZone)
          : _end;
      if (_allDay ? !end.isAfter(start) : end.isBefore(start)) {
        setState(() => _error = '終了日時は開始日時以降にしてください');
        return;
      }
      final input = CalendarEventDto(
        version: widget.event?.version,
        id: widget.event?.id ?? '',
        groupId: widget.groupId,
        labelId:
            _labelId!.startsWith('group:') || _labelId!.startsWith('member:')
            ? ''
            : _labelId!,
        labelType: _labelId == 'group:'
            ? 'group'
            : _labelId!.startsWith('member:')
            ? 'member'
            : 'custom',
        memberId: _labelId!.startsWith('member:') ? _labelId!.substring(7) : '',
        title: _title.text.trim(),
        url: _url.text.trim(),
        memo: _memo.text,
        locationName: _locationName.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        startDateTime: start,
        endDateTime: end,
        isAllDay: _allDay,
        notificationMinutesBefore: _notifications ?? [],
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
              expectedSeries: _seriesAtOpen,
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
                      deleting
                          ? '独立した通常予定は変更・削除されません。'
                          : '独立した通常予定は変更・削除されません。新系列へ取消情報は引き継ぎません。',
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
          .changeRecurringEvent(
            widget.event!,
            scope,
            expectedSeries: _seriesAtOpen,
          );
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
        .deleteEvent(widget.event!.id, expectedVersion: widget.event!.version);
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
    final labels = state.displayLabels
        .where(
          (label) => label.isSelectable || label.id == widget.event?.labelKey,
        )
        .toList();
    final preferences = ref.watch(calendarPreferencesNotifierProvider);
    final notificationPreferences = ref.watch(
      calendarNotificationPreferencesNotifierProvider,
    );
    final notificationSettings = notificationPreferences.value?.preferences;
    if (_notifications == null && notificationSettings != null) {
      _notifications = List.of(
        _allDay ? notificationSettings.allDay : notificationSettings.timed,
      );
      _initialNotifications = List.of(_notifications!);
    }
    final dateInputStyle = TextButton.styleFrom(
      alignment: Alignment.centerLeft,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
    );
    return EditDiscardScope(
      isSaving: state.isSaving,
      isDirty:
          _editValues != _initialValues ||
          (_notifications ?? []).join(',') !=
              (_initialNotifications ?? []).join(','),
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
                      padding: EdgeInsets.only(
                        top: MediaQuery.textScalerOf(context).scale(8),
                      ),
                      child: Form(
                        key: _form,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 16,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _title,
                              onChanged: (_) => setState(() {}),
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
                                      enabled: label.isSelectable,
                                      child:
                                          label.labelType == 'member' &&
                                              label.isSelectable
                                          ? Semantics(
                                              label: label.name,
                                              excludeSemantics: true,
                                              child: Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      label.name.substring(
                                                        0,
                                                        label.name.length -
                                                            'の予定'.length,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                  const Text('の予定'),
                                                ],
                                              ),
                                            )
                                          : Text(
                                              label.name,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
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
                              onChanged:
                                  state.isSaving || notificationSettings == null
                                  ? null
                                  : (value) => setState(() {
                                      _allDay = value;
                                      _notifications = List.of(
                                        value
                                            ? notificationSettings.allDay
                                            : notificationSettings.timed,
                                      );
                                    }),
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
                              subtitle: Text(_recurrence.summary),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: state.isSaving
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
                            if (notificationSettings != null)
                              CalendarNotificationEditor(
                                allDay: _allDay,
                                values: _notifications ?? [],
                                enabled: !state.isSaving,
                                onChanged: (value) =>
                                    setState(() => _notifications = value),
                              ),
                            if (notificationPreferences.hasError)
                              TextButton(
                                onPressed: () => ref.invalidate(
                                  calendarNotificationPreferencesNotifierProvider,
                                ),
                                child: const Text('通知設定を再取得'),
                              ),
                            if (!_allDay && preferences.hasError)
                              TextButton(
                                onPressed: () => ref.invalidate(
                                  calendarPreferencesNotifierProvider,
                                ),
                                child: const Text('標準時間を再取得'),
                              ),
                            TextFormField(
                              controller: _url,
                              onChanged: (_) => setState(() {}),
                              enabled: !state.isSaving,
                              keyboardType: TextInputType.url,
                              decoration: InputDecoration(
                                labelText: 'URL',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  tooltip: 'URLを開く',
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed:
                                      state.isSaving || _url.text.trim().isEmpty
                                      ? null
                                      : _openUrl,
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: _memo,
                              onChanged: (_) => setState(() {}),
                              enabled: !state.isSaving,
                              minLines: 3,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              decoration: const InputDecoration(
                                labelText: 'メモ',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            CalendarLocationField(
                              controller: _locationName,
                              enabled: !state.isSaving,
                              onChanged: (_) => setState(() {
                                _latitude = null;
                                _longitude = null;
                              }),
                              onSelected: (candidate) => setState(() {
                                _latitude = candidate.coordinate.latitude;
                                _longitude = candidate.coordinate.longitude;
                              }),
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
                            : () => Navigator.maybePop(context),
                        child: const Text('キャンセル'),
                      ),
                      ElevatedButton(
                        onPressed:
                            state.isSaving || notificationSettings == null
                            ? null
                            : _save,
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
