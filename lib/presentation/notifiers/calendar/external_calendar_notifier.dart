import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/application/exceptions/external_calendar_exception.dart';
import 'package:memora/application/usecases/calendar/external_calendar_usecase.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/providers/external_calendar_providers.dart';
import 'package:memora/presentation/notifiers/calendar/external_calendar_state.dart';

part 'external_calendar_notifier.g.dart';

@Riverpod(keepAlive: true)
class ExternalCalendarNotifier extends _$ExternalCalendarNotifier {
  int _version = 0;
  String? _owner;
  Future<void>? _initialization;
  StreamSubscription<void>? _changes;

  @override
  ExternalCalendarState build() {
    _version++;
    _initialization = null;
    _owner = ref.watch(externalCalendarOwnerProvider);
    final now = ref.watch(appClockProvider).now();
    ref.onDispose(() {
      _version++;
      unawaited(_changes?.cancel());
      _changes = null;
    });
    return ExternalCalendarState(month: DateTime(now.year, now.month));
  }

  bool _active(int version) => ref.mounted && version == _version;
  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (_owner == null || !ref.read(externalCalendarSupportedProvider)) return;
    final usecase = ref.read(externalCalendarUsecaseProvider)!;
    final version = ++_version;
    state = state.copyWith(isLoading: true, error: '');
    try {
      final permitted = await usecase.hasReadPermission();
      if (!_active(version)) return;
      state = state.copyWith(hasPermission: permitted, isLoading: false);
      if (permitted) await refresh();
    } catch (error) {
      _failure(error, version);
    }
  }

  void _observe(ExternalCalendarUsecase usecase) {
    _changes ??= usecase.changes.listen(
      (_) {
        if (ref.mounted && !state.isBusy) unawaited(refresh());
      },
      onError: (Object _) {
        if (ref.mounted && !state.isBusy) unawaited(refresh());
      },
    );
  }

  Future<void> setPeriod(DateTime day) async {
    final month = DateTime(day.year, day.month);
    if (state.month == month) return;
    if (!state.isBusy && state.hasPermission) _version++;
    state = state.copyWith(
      month: month,
      isLoading: false,
      failures: {},
      error: '',
    );
    if (!state.isBusy && state.hasPermission) await refresh();
  }

  Future<void> requestAccess() async {
    final owner = _owner;
    if (owner == null || state.isBusy) return;
    final usecase = ref.read(externalCalendarUsecaseProvider)!;
    final version = ++_version;
    state = state.copyWith(isBusy: true, isLoading: false, error: '');
    try {
      final connections = await usecase.requestAccess(owner);
      if (!_active(version)) return;
      state = state.copyWith(
        hasPermission: true,
        connections: connections,
        isBusy: false,
      );
      await refresh();
    } catch (error) {
      _failure(error, version);
    }
  }

  Future<void> selectCalendars(String accountId, Set<String> ids) async {
    final owner = _owner;
    final connection = state.connections
        .where((v) => v.account.id == accountId)
        .firstOrNull;
    if (owner == null ||
        connection == null ||
        !state.hasPermission ||
        state.isBusy) {
      return;
    }
    final usecase = ref.read(externalCalendarUsecaseProvider)!;
    final version = ++_version;
    state = state.copyWith(isBusy: true, isLoading: false, error: '');
    try {
      final next = await usecase.select(owner, connection, ids);
      if (!_active(version)) return;
      state = state.copyWith(
        connections: [
          for (final entry in state.connections)
            if (entry.account.id == accountId) next else entry,
        ],
        eventsByAccount: {
          ...state.eventsByAccount,
          accountId:
              state.eventsByAccount[accountId]
                  ?.where((v) => ids.contains(v.calendarId))
                  .toList() ??
              [],
        },
        isBusy: false,
      );
      await refresh();
    } catch (error) {
      _failure(error, version);
    }
  }

  Future<void> refresh() async {
    final owner = _owner;
    if (owner == null || state.isBusy) return;
    final usecase = ref.read(externalCalendarUsecaseProvider)!;
    final version = ++_version;
    final month = state.month;
    state = state.copyWith(isLoading: true, error: '');
    try {
      final permitted = await usecase.hasReadPermission();
      if (!_active(version)) return;
      if (!permitted) {
        _clearAccess();
        return;
      }
      final connections = await usecase.restore(owner);
      if (!_active(version)) return;
      final ids = connections.map((v) => v.account.id).toSet();
      state = state.copyWith(
        hasPermission: true,
        connections: connections,
        calendarsByAccount: {
          for (final entry in state.calendarsByAccount.entries)
            if (ids.contains(entry.key)) entry.key: entry.value,
        },
        eventsByAccount: {
          for (final entry in state.eventsByAccount.entries)
            if (ids.contains(entry.key)) entry.key: entry.value,
        },
        failures: {
          for (final entry in state.failures.entries)
            if (ids.contains(entry.key)) entry.key: entry.value,
        },
      );
      _observe(usecase);
      for (final connection in connections) {
        final id = connection.account.id;
        try {
          final calendars = await usecase.calendars(id);
          if (!_active(version)) return;
          state = state.copyWith(
            calendarsByAccount: {...state.calendarsByAccount, id: calendars},
          );
          final selected = calendars
              .where((v) => connection.calendarIds.contains(v.id))
              .toList();
          final events = selected.isEmpty
              ? <ExternalCalendarEventDto>[]
              : await usecase.events(
                  id,
                  selected,
                  DateTime(month.year, month.month - 1),
                  DateTime(month.year, month.month + 2),
                );
          if (!_active(version)) return;
          state = state.copyWith(
            eventsByAccount: {...state.eventsByAccount, id: events},
            failures: {...state.failures}..remove(id),
          );
        } catch (error) {
          if (!_active(version)) return;
          final failure = _externalFailure(error);
          if (failure.kind == ExternalCalendarFailure.permission) {
            _clearAccess(error: failure.message);
            return;
          }
          state = state.copyWith(failures: {...state.failures, id: failure});
        }
      }
      if (_active(version)) {
        state = state.copyWith(isLoading: false);
        await _updateWidgets();
      }
    } catch (error) {
      _failure(error, version);
    }
  }

  void _clearAccess({String error = ''}) {
    unawaited(_changes?.cancel());
    _changes = null;
    state = ExternalCalendarState(month: state.month, error: error);
    unawaited(_updateWidgets());
  }

  Future<void> _updateWidgets() async {
    if (!ref.mounted) return;
    try {
      await ref.read(externalCalendarWidgetRefreshProvider)();
    } catch (_) {}
  }

  ExternalCalendarException _externalFailure(Object error) =>
      error is ExternalCalendarException
      ? error
      : const ExternalCalendarException(ExternalCalendarFailure.unavailable);
  void _failure(Object error, int version) {
    if (!_active(version)) return;
    final failure = _externalFailure(error);
    if (failure.kind == ExternalCalendarFailure.permission) {
      _clearAccess(error: failure.message);
    } else {
      state = state.copyWith(
        isLoading: false,
        isBusy: false,
        error: failure.message,
      );
    }
  }
}
