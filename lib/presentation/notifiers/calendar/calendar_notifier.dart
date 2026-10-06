import 'package:memora/application/usecases/calendar/change_calendar_recurrence_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_state.dart';

part 'calendar_notifier.g.dart';

@riverpod
class CalendarNotifier extends _$CalendarNotifier {
  int _loadVersion = 0;
  List<CalendarEventDto> _series = const [];

  @override
  CalendarState build(String groupId) {
    final now = ref.watch(appClockProvider).now();
    return CalendarState(selectedDate: DateTime(now.year, now.month, now.day));
  }

  void selectDate(DateTime day) {
    state = state.copyWith(
      selectedDate: DateTime(day.year, day.month, day.day),
      events: _expand(_series, day),
    );
  }

  List<CalendarEventDto> _expand(List<CalendarEventDto> series, DateTime day) {
    final from = DateTime(day.year, day.month, -6);
    final to = DateTime(day.year, day.month + 1, 8);
    final expander = ref.read(calendarRecurrenceExpanderProvider);
    return series.expand((event) => expander.expand(event, from, to)).toList();
  }

  Future<void> load() async {
    final version = ++_loadVersion;
    state = state.copyWith(isLoading: true, loadError: '');
    try {
      final results = await Future.wait<Object>([
        ref.read(getCalendarEventsUsecaseProvider).execute(groupId),
        ref.read(getCalendarLabelsUsecaseProvider).execute(groupId),
      ]);
      if (!ref.mounted || version != _loadVersion) return;
      final series = results[0] as List<CalendarEventDto>;
      final expanded = _expand(series, state.selectedDate);
      _series = series;
      state = state.copyWith(
        events: expanded,
        labels: results[1] as List<CalendarLabelDto>,
        isLoading: false,
      );
    } catch (_) {
      if (!ref.mounted || version != _loadVersion) return;
      state = state.copyWith(
        isLoading: false,
        loadError: '予定と色ラベルを取得できませんでした。再読み込みしてください',
      );
    }
  }

  Future<bool> _mutate(Future<void> Function() action) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, mutationError: '');
    try {
      await action();
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          isSaving: false,
          mutationError: e is ApplicationValidationException
              ? e.message
              : '保存できませんでした。再試行してください',
        );
      }
      return false;
    }
    if (!ref.mounted) return true;
    await load();
    if (ref.mounted) state = state.copyWith(isSaving: false);
    return true;
  }

  CalendarEventDto? seriesForEvent(String id) =>
      _series.where((v) => v.id == id).firstOrNull;

  Future<bool> changeRecurringEvent(
    CalendarEventDto occurrence,
    CalendarChangeScope scope, {
    CalendarEventDto? changes,
  }) => _mutate(() async {
    final source = _series.where((v) => v.id == occurrence.id).firstOrNull;
    if (source == null ||
        occurrence.groupId != groupId ||
        occurrence.originalStartDateTime == null) {
      throw const ApplicationValidationException('変更する予定が見つかりません。再読み込みしてください');
    }
    await ref
        .read(changeCalendarRecurrenceUsecaseProvider)
        .execute(
          source,
          occurrence.originalStartDateTime!,
          scope,
          changes: changes,
        );
  });

  CalendarEventDto? originalOccurrenceForEvent(CalendarEventDto occurrence) {
    final source = seriesForEvent(occurrence.id);
    final key = occurrence.originalStartDateTime;
    if (source == null || key == null || occurrence.groupId != groupId) {
      return null;
    }
    return ref
        .read(calendarRecurrenceExpanderProvider)
        .expand(
          source.copyWith(overrides: []),
          key,
          key.add(const Duration(days: 1)),
        )
        .where((value) => value.originalStartDateTime == key)
        .firstOrNull;
  }

  Future<bool> resetRecurringEvent(CalendarEventDto occurrence) =>
      _mutate(() async {
        final source = seriesForEvent(occurrence.id);
        if (source == null ||
            occurrence.groupId != groupId ||
            occurrence.originalStartDateTime == null) {
          throw const ApplicationValidationException(
            'リセットする予定が見つかりません。再読み込みしてください',
          );
        }
        await ref
            .read(changeCalendarRecurrenceUsecaseProvider)
            .resetOverride(source, occurrence.originalStartDateTime!);
      });

  ({int reset, int retained}) recurrenceImpact(
    CalendarEventDto occurrence,
    CalendarChangeScope scope,
  ) {
    final source = _series.where((v) => v.id == occurrence.id).firstOrNull;
    final key = occurrence.originalStartDateTime;
    if (source == null || key == null) return (reset: 0, retained: 0);
    final reset = source.overrides
        .where(
          (v) => switch (scope) {
            CalendarChangeScope.only => v.originalStartDateTime == key,
            CalendarChangeScope.following => !v.originalStartDateTime.isBefore(
              key,
            ),
            CalendarChangeScope.all => true,
          },
        )
        .length;
    return (reset: reset, retained: source.overrides.length - reset);
  }

  Future<bool> saveEvent(CalendarEventDto event) => _mutate(() async {
    if (event.originalStartDateTime != null ||
        _series.any((v) => v.id == event.id && v.recurrenceRule != null)) {
      throw const ApplicationValidationException('繰り返し予定は変更範囲を指定してください');
    }
    if (event.groupId != groupId ||
        !state.labels.any(
          (label) => label.id == event.labelId && label.groupId == groupId,
        )) {
      throw const ApplicationValidationException('同じグループの色ラベルを指定してください');
    }
    if (event.id.isEmpty) {
      await ref.read(createCalendarEventUsecaseProvider).execute(event);
    } else {
      await ref.read(updateCalendarEventUsecaseProvider).execute(event);
    }
  });

  Future<bool> deleteEvent(String id) => _mutate(() async {
    if (_series.any((v) => v.id == id && v.recurrenceRule != null)) {
      throw const ApplicationValidationException('繰り返し予定は削除範囲を指定してください');
    }
    if (!state.events.any(
      (event) => event.id == id && event.groupId == groupId,
    )) {
      throw const ApplicationValidationException('削除する予定が見つかりません');
    }
    await ref.read(deleteCalendarEventUsecaseProvider).execute(id);
  });

  Future<bool> saveLabel(CalendarLabelDto label) => _mutate(() async {
    if (label.groupId != groupId) {
      throw const ApplicationValidationException('同じグループの色ラベルを指定してください');
    }
    await ref.read(saveCalendarLabelUsecaseProvider).execute(label);
  });

  Future<bool> reorderLabels(int oldIndex, int newIndex) async {
    if (state.isSaving ||
        state.isLoading ||
        state.loadError.isNotEmpty ||
        oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= state.labels.length ||
        newIndex >= state.labels.length) {
      return false;
    }
    if (oldIndex == newIndex) return true;
    final previous = state.labels;
    final ordered = previous.toList();
    ordered.insert(newIndex, ordered.removeAt(oldIndex));
    final updated = [
      for (var index = 0; index < ordered.length; index++)
        ordered[index].copyWith(sortOrder: index),
    ];
    state = state.copyWith(labels: updated);
    final success = await _mutate(() async {
      await ref
          .read(reorderCalendarLabelsUsecaseProvider)
          .execute(groupId, ordered.map((label) => label.id).toList());
    });
    if (!success && ref.mounted) state = state.copyWith(labels: previous);
    return success;
  }

  Future<bool> deleteLabel(String id) => _mutate(() async {
    if (!state.labels.any(
      (label) => label.id == id && label.groupId == groupId,
    )) {
      throw const ApplicationValidationException('削除する色ラベルが見つかりません');
    }
    if (_series.any(
      (event) =>
          event.labelId == id ||
          event.overrides.any((v) => !v.isCancelled && v.labelId == id),
    )) {
      throw const ApplicationValidationException('予定で使用中の色ラベルは削除できません');
    }
    await ref.read(deleteCalendarLabelUsecaseProvider).execute(id);
  });
}
