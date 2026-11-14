import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/providers/calendar_group_settings_providers.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_group_settings_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_state.dart';

part 'multi_group_calendar_notifier.g.dart';

class MultiGroupCalendarState {
  MultiGroupCalendarState({required this.calendar, Map<String, CalendarState> groups = const {}}) : groups = Map.unmodifiable(groups);
  final CalendarState calendar;
  final Map<String, CalendarState> groups;
  Set<String> get failedGroupIds => {for (final entry in groups.entries) if (entry.value.loadError.isNotEmpty) entry.key};
}

@riverpod
class MultiGroupCalendarNotifier extends _$MultiGroupCalendarNotifier {
  final _subscriptions = <String, ProviderSubscription<CalendarState>>{};
  final _groups = <String, CalendarState>{};
  late DateTime _date;
  int _generation = 0;
  @override
  MultiGroupCalendarState build() {
    ref.watch(calendarSettingsOwnerProvider);
    final generation = ++_generation;
    _subscriptions.clear();
    _groups.clear();
    final now = ref.read(appClockProvider).now();
    _date = DateTime(now.year, now.month, now.day);
    ref.onDispose(() {
      _generation++;
      for (final subscription in _subscriptions.values) { subscription.close(); }
      _subscriptions.clear();
      _groups.clear();
    });
    ref.listen(calendarGroupSettingsNotifierProvider, (_, next) => _sync(next.effectiveSettings.visibleGroupIds));
    Future.microtask(() {
      if (ref.mounted && generation == _generation) _sync(ref.read(calendarGroupSettingsNotifierProvider).effectiveSettings.visibleGroupIds);
    });
    return MultiGroupCalendarState(calendar: CalendarState(selectedDate: _date));
  }

  void _sync(Set<String> ids) {
    for (final id in _subscriptions.keys.toList()) {
      if (!ids.contains(id)) {
        _subscriptions.remove(id)!.close();
        _groups.remove(id);
      }
    }
    for (final id in ids) {
      if (_subscriptions.containsKey(id)) continue;
      final provider = calendarNotifierProvider(id);
      final generation = _generation;
      _subscriptions[id] = ref.listen(provider, (_, next) {
        if (!ref.mounted || generation != _generation || !_subscriptions.containsKey(id)) return;
        _groups[id] = next;
        _publish();
      });
      ref.read(provider.notifier).selectDate(_date);
      _groups[id] = ref.read(provider);
      unawaited(ref.read(provider.notifier).load());
    }
    _publish();
  }

  void _publish() {
    final errors = [for (final entry in _groups.entries) if (entry.value.loadError.isNotEmpty) '${entry.value.group?.name ?? entry.key}: ${entry.value.loadError}'];
    state = MultiGroupCalendarState(groups: _groups, calendar: CalendarState(
      selectedDate: _date,
      events: [for (final group in _groups.values) ...group.events],
      labels: [for (final group in _groups.values) ...group.displayLabels],
      isLoading: _groups.values.any((g) => g.isLoading),
      isSaving: _groups.values.any((g) => g.isSaving),
      isWatching: _groups.values.every((g) => g.isWatching),
      loadError: errors.join('\n'),
      hasLoadedEvents: _groups.values.every((g) => g.hasLoadedEvents),
      hasLoadedLabels: _groups.values.every((g) => g.hasLoadedLabels),
    ));
  }

  void selectDate(DateTime day) {
    _date = DateTime(day.year, day.month, day.day);
    for (final id in _subscriptions.keys.toList()) { ref.read(calendarNotifierProvider(id).notifier).selectDate(_date); }
    _publish();
  }
  Future<void> load() async {
    await Future.wait([for (final id in _subscriptions.keys.toList()) ref.read(calendarNotifierProvider(id).notifier).load()]);
  }
  Future<void> retryFailed() async {
    await Future.wait([for (final id in state.failedGroupIds) ref.read(calendarNotifierProvider(id).notifier).load()]);
  }
}
