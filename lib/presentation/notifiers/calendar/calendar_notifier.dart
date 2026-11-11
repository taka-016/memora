import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifications_notifier.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/composition_root/providers/group_providers.dart';

import 'dart:async';

import 'package:memora/application/usecases/calendar/change_calendar_recurrence_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_state.dart';

part 'calendar_notifier.g.dart';

@riverpod
class CalendarNotifier extends _$CalendarNotifier {
  int _loadVersion = 0;
  int _eventsVersion = 0;
  StreamSubscription<GroupDto?>? _groupSubscription;
  bool _groupWaiting = false;
  StreamSubscription<List<CalendarEventDto>>? _eventsSubscription;
  StreamSubscription<List<CalendarLabelDto>>? _labelsSubscription;
  List<CalendarLabelDto>? _receivedLabels;
  bool _reordering = false;
  bool _eventsWaiting = false;
  bool _labelsWaiting = false;
  List<CalendarEventDto> _series = const [];

  @override
  CalendarState build(String groupId) {
    ref.onDispose(() {
      _loadVersion++;
      _eventsVersion++;
      unawaited(_groupSubscription?.cancel());
      unawaited(_eventsSubscription?.cancel());
      unawaited(_labelsSubscription?.cancel());
    });
    final watching = ref.watch(watchCalendarEventsUsecaseProvider) != null;
    final now = ref.watch(appClockProvider).now();
    return CalendarState(
      selectedDate: DateTime(now.year, now.month, now.day),
      isWatching: watching,
    );
  }

  void selectDate(DateTime day) {
    final monthChanged = state.month != DateTime(day.year, day.month);
    state = state.copyWith(
      selectedDate: DateTime(day.year, day.month, day.day),
      events: monthChanged ? _expand(_series, day) : null,
    );
    if (monthChanged &&
        state.isWatching &&
        (state.isLoading || state.hasLoadedEvents)) {
      unawaited(_watchEvents(_loadVersion));
    }
  }

  List<CalendarEventDto> _expand(List<CalendarEventDto> series, DateTime day) {
    final period = CalendarEventPeriod.forMonth(day);
    final expander = ref.read(calendarRecurrenceExpanderProvider);
    return series
        .expand((event) => expander.expand(event, period.from, period.to))
        .toList();
  }

  Future<void> load() async {
    final version = ++_loadVersion;
    if (state.isWatching) {
      await _watch(version);
      return;
    }
    state = state.copyWith(isLoading: true, loadError: '');
    try {
      final results = await Future.wait<Object?>([
        ref
            .read(getCalendarEventsUsecaseProvider)
            .execute(groupId, period: null),
        ref.read(getCalendarLabelsUsecaseProvider).execute(groupId),
        ref.read(getGroupWithMembersByIdUsecaseProvider).execute(groupId),
      ]);
      if (!ref.mounted || version != _loadVersion) return;
      if (results[2] == null) {
        throw const ApplicationValidationException('グループが見つかりません');
      }
      final series = results[0] as List<CalendarEventDto>;
      final expanded = _expand(series, state.selectedDate);
      _series = series;
      state = state.copyWith(
        group: results[2] as GroupDto,
        groupLoadError: '',
        events: expanded,
        labels: results[1] as List<CalendarLabelDto>,
        isLoading: false,
        hasLoadedEvents: true,
        hasLoadedLabels: true,
      );
    } catch (_) {
      if (!ref.mounted || version != _loadVersion) return;
      state = state.copyWith(
        isLoading: false,
        loadError: '予定と色ラベルを取得できませんでした。再読み込みしてください',
      );
    }
  }

  Future<void> _watch(int version) async {
    await _groupSubscription?.cancel();
    await _labelsSubscription?.cancel();
    if (!ref.mounted || version != _loadVersion) return;
    _groupWaiting = true;
    _eventsWaiting = true;
    _labelsWaiting = true;
    state = state.copyWith(isLoading: true);
    bool active() => ref.mounted && version == _loadVersion;
    void failure(bool events) {
      if (!active()) return;
      if (events) {
        _eventsWaiting = false;
      } else {
        _labelsWaiting = false;
      }
      final target = events ? '予定' : '色ラベル';
      final hasLoaded = events ? state.hasLoadedEvents : state.hasLoadedLabels;
      _receiveStatus(
        events: events,
        error: hasLoaded
            ? '$targetを自動更新できませんでした。再試行してください'
            : '$targetはまだ取得できていません。再試行してください',
      );
    }

    await _watchEvents(version);
    if (!active()) return;
    try {
      _labelsSubscription = ref
          .read(watchCalendarLabelsUsecaseProvider)!
          .execute(groupId)
          .listen((labels) {
            if (!active()) return;
            _labelsWaiting = false;
            _receivedLabels = labels;
            state = state.copyWith(
              labels: _reordering ? null : labels,
              hasLoadedLabels: true,
            );
            _receiveStatus(events: false);
          }, onError: (Object _) => failure(false));
    } catch (_) {
      failure(false);
    }
    void groupFailure() {
      if (!active()) return;
      _groupWaiting = false;
      state = state.copyWith(groupLoadError: 'グループ情報を取得できませんでした。再試行してください');
      _receiveStatus(events: true, error: state.eventLoadError);
    }

    void receiveGroup(GroupDto? group) {
      if (!active()) return;
      if (group == null) {
        groupFailure();
        return;
      }
      _groupWaiting = false;
      state = state.copyWith(group: group, groupLoadError: '');
      _receiveStatus(events: true, error: state.eventLoadError);
    }

    try {
      final watcher = ref.read(watchCalendarGroupUsecaseProvider);
      if (watcher == null) {
        receiveGroup(
          await ref
              .read(getGroupWithMembersByIdUsecaseProvider)
              .execute(groupId),
        );
      } else {
        _groupSubscription = watcher
            .execute(groupId)
            .listen(receiveGroup, onError: (Object _) => groupFailure());
      }
    } catch (_) {
      groupFailure();
    }
  }

  Future<void> _watchEvents(int version) async {
    final eventVersion = ++_eventsVersion;
    bool active() =>
        ref.mounted &&
        version == _loadVersion &&
        eventVersion == _eventsVersion;
    await _eventsSubscription?.cancel();
    if (!active()) return;
    _eventsWaiting = true;
    state = state.copyWith(isLoading: true);
    void failure() {
      if (!active()) return;
      _eventsWaiting = false;
      _receiveStatus(
        events: true,
        error: state.hasLoadedEvents
            ? '予定を自動更新できませんでした。再試行してください'
            : '予定はまだ取得できていません。再試行してください',
      );
    }

    try {
      _eventsSubscription = ref
          .read(watchCalendarEventsUsecaseProvider)!
          .execute(
            groupId,
            period: CalendarEventPeriod.forMonth(state.selectedDate),
          )
          .listen((series) {
            if (!active()) return;
            try {
              final expanded = _expand(series, state.selectedDate);
              _series = series;
              _eventsWaiting = false;
              state = state.copyWith(events: expanded, hasLoadedEvents: true);
              _receiveStatus(events: true);
            } catch (_) {
              failure();
            }
          }, onError: (Object _) => failure());
    } catch (_) {
      failure();
    }
  }

  void _receiveStatus({required bool events, String error = ''}) {
    final eventError = events ? error : state.eventLoadError;
    final labelError = events ? state.labelLoadError : error;
    state = state.copyWith(
      eventLoadError: eventError,
      labelLoadError: labelError,
      loadError: [
        eventError,
        labelError,
        state.groupLoadError,
      ].where((value) => value.isNotEmpty).join('\n'),
      isLoading: _eventsWaiting || _labelsWaiting || _groupWaiting,
    );
  }

  Future<bool> _mutate(Future<void> Function() action) async {
    if (state.isSaving) return false;
    final refreshWidget = ref.read(refreshSelectedCalendarWidgetCacheProvider);
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
    unawaited(_refreshWidgetAfterMutation(refreshWidget));
    if (!ref.mounted) return true;
    if (ref.exists(calendarNotificationsNotifierProvider)) {
      unawaited(
        ref.read(calendarNotificationsNotifierProvider.notifier).refresh(),
      );
    }
    if (!ref.mounted) return true;
    if (!state.isWatching) await load();
    if (ref.mounted) state = state.copyWith(isSaving: false);
    return true;
  }

  Future<void> _refreshWidgetAfterMutation(
    Future<void> Function() refreshWidget,
  ) async {
    try {
      await refreshWidget();
    } catch (error, stackTrace) {
      logger.w('保存後のウィジェット更新に失敗しました', error: error, stackTrace: stackTrace);
    }
  }

  CalendarEventDto? seriesForEvent(String id) =>
      _series.where((v) => v.id == id).firstOrNull;

  Future<bool> changeRecurringEvent(
    CalendarEventDto occurrence,
    CalendarChangeScope scope, {
    CalendarEventDto? changes,
    CalendarEventDto? expectedSeries,
  }) => _mutate(() async {
    final source =
        expectedSeries ??
        _series.where((v) => v.id == occurrence.id).firstOrNull;
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

  Future<bool> saveEvent(CalendarEventDto event) => _mutate(() async {
    if (event.originalStartDateTime != null ||
        _series.any((v) => v.id == event.id && v.recurrenceRule != null)) {
      throw const ApplicationValidationException('繰り返し予定は変更範囲を指定してください');
    }
    if (event.groupId != groupId ||
        !state.displayLabels.any(
          (label) =>
              label.id == event.labelKey &&
              label.groupId == groupId &&
              (label.isSelectable ||
                  _series.any(
                    (source) =>
                        source.id == event.id &&
                        source.labelKey == event.labelKey,
                  )),
        )) {
      throw const ApplicationValidationException('同じグループの色ラベルを指定してください');
    }
    if (event.id.isEmpty) {
      await ref.read(createCalendarEventUsecaseProvider).execute(event);
    } else {
      await ref.read(updateCalendarEventUsecaseProvider).execute(event);
    }
  });

  Future<bool> deleteEvent(String id, {int? expectedVersion}) =>
      _mutate(() async {
        if (_series.any((v) => v.id == id && v.recurrenceRule != null)) {
          throw const ApplicationValidationException('繰り返し予定は削除範囲を指定してください');
        }
        if (!state.events.any(
          (event) => event.id == id && event.groupId == groupId,
        )) {
          throw const ApplicationValidationException('削除する予定が見つかりません');
        }
        await ref
            .read(deleteCalendarEventUsecaseProvider)
            .execute(id, expectedVersion: expectedVersion);
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
    _reordering = true;
    _receivedLabels = null;
    state = state.copyWith(labels: updated);
    final success = await _mutate(() async {
      await ref
          .read(reorderCalendarLabelsUsecaseProvider)
          .execute(
            groupId,
            ordered.map((label) => label.id).toList(),
            expectedVersions: {
              for (final label in previous)
                if (label.version != null) label.id: label.version!,
            },
          );
    });
    _reordering = false;
    if (ref.mounted) {
      if (_receivedLabels != null) {
        state = state.copyWith(labels: _receivedLabels);
      } else if (!success) {
        state = state.copyWith(labels: previous);
      }
    }
    return success;
  }

  Future<bool> deleteLabel(String id, {int? expectedVersion}) => _mutate(
    () async {
      if (!state.labels.any(
        (label) => label.id == id && label.groupId == groupId,
      )) {
        throw const ApplicationValidationException('削除する色ラベルが見つかりません');
      }
      if (_series.any(
        (event) =>
            event.labelType == 'custom' && event.labelId == id,
      )) {
        throw const ApplicationValidationException('予定で使用中の色ラベルは削除できません');
      }
      await ref
          .read(deleteCalendarLabelUsecaseProvider)
          .execute(id, expectedVersion: expectedVersion);
    },
  );
}
