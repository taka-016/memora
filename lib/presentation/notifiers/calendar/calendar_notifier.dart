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

  @override
  CalendarState build(String groupId) {
    final now = ref.watch(appClockProvider).now();
    return CalendarState(selectedDate: DateTime(now.year, now.month, now.day));
  }

  void selectDate(DateTime day) {
    state = state.copyWith(
      selectedDate: DateTime(day.year, day.month, day.day),
    );
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
      state = state.copyWith(
        events: results[0] as List<CalendarEventDto>,
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

  Future<bool> saveEvent(CalendarEventDto event) => _mutate(() async {
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
    if (state.events.any((event) => event.labelId == id)) {
      throw const ApplicationValidationException('予定で使用中の色ラベルは削除できません');
    }
    await ref.read(deleteCalendarLabelUsecaseProvider).execute(id);
  });
}
