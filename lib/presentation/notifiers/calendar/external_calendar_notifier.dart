import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memora/application/exceptions/external_calendar_exception.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/providers/external_calendar_providers.dart';
import 'package:memora/presentation/notifiers/calendar/external_calendar_state.dart';

part 'external_calendar_notifier.g.dart';

@Riverpod(keepAlive: true)
class ExternalCalendarNotifier extends _$ExternalCalendarNotifier {
  int _version = 0;
  String? _owner;
  Future<void>? _initialization;

  @override
  ExternalCalendarState build() {
    _version++;
    _initialization = null;
    _owner = ref.watch(externalCalendarOwnerProvider);
    final now = ref.watch(appClockProvider).now();
    ref.onDispose(() {
      _version++;
    });
    return ExternalCalendarState(month: DateTime(now.year, now.month));
  }

  bool _active(int version) => ref.mounted && version == _version;
  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    final owner = _owner;
    if (owner == null || !ref.read(externalCalendarSupportedProvider)) return;
    final usecase = ref.read(externalCalendarUsecaseProvider)!;
    final version = ++_version;
    state = state.copyWith(isLoading: true, error: '');
    try {
      final connections = await usecase.restore(owner);
      if (!_active(version)) return;
      state = state.copyWith(connections: connections, isLoading: false);
      await refresh();
    } catch (error) {
      _failure(error, version);
    }
  }

  Future<void> setPeriod(DateTime day) async {
    final month = DateTime(day.year, day.month);
    if (state.month == month) return;
    if (!state.isBusy && state.connections.isNotEmpty) _version++;
    state = state.copyWith(
      month: month,
      isLoading: false,
      failures: {},
      error: '',
    );
    if (!state.isBusy) await refresh();
  }

  Future<void> connect() async {
    final owner = _owner;
    if (owner == null || state.isBusy) return;
    final usecase = ref.read(externalCalendarUsecaseProvider)!;
    final version = ++_version;
    state = state.copyWith(isBusy: true, isLoading: false, error: '');
    try {
      final connections = await usecase.connect(owner);
      if (!_active(version)) return;
      state = state.copyWith(connections: connections, isBusy: false);
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
    if (owner == null || connection == null || state.isBusy) return;
    final usecase = ref.read(externalCalendarUsecaseProvider)!;
    final version = ++_version;
    state = state.copyWith(isBusy: true, isLoading: false, error: '');
    try {
      final next = await usecase.select(owner, connection, ids);
      if (!_active(version)) return;
      state = state.copyWith(
        connections: next,
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

  Future<void> refresh({String? accountId}) async {
    if (_owner == null || state.connections.isEmpty || state.isBusy) return;
    final usecase = ref.read(externalCalendarUsecaseProvider)!;
    final version = ++_version;
    final month = state.month;
    final connections = state.connections
        .where((v) => accountId == null || v.account.id == accountId)
        .toList();
    state = state.copyWith(isLoading: true, error: '');
    for (final connection in connections) {
      final id = connection.account.id;
      try {
        final calendars = await usecase.calendars(id);
        if (!_active(version)) return;
        state = state.copyWith(
          calendarsByAccount: {...state.calendarsByAccount, id: calendars},
        );
        if (connection.calendarIds.any(
          (selected) => !calendars.any((v) => v.id == selected),
        )) {
          throw const ExternalCalendarException(
            ExternalCalendarFailure.unavailable,
          );
        }
        final selected = calendars
            .where((v) => connection.calendarIds.contains(v.id))
            .toList();
        final events = selected.isEmpty
            ? <Never>[]
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
        state = state.copyWith(
          failures: {...state.failures, id: _externalFailure(error)},
        );
      }
    }
    if (_active(version)) state = state.copyWith(isLoading: false);
  }

  Future<void> disconnect(String accountId) async {
    final owner = _owner;
    if (owner == null || state.isBusy) return;
    final usecase = ref.read(externalCalendarUsecaseProvider)!;
    final version = ++_version;
    state = state.copyWith(
      connections: state.connections
          .where((v) => v.account.id != accountId)
          .toList(),
      calendarsByAccount: {...state.calendarsByAccount}..remove(accountId),
      eventsByAccount: {...state.eventsByAccount}..remove(accountId),
      failures: {...state.failures}..remove(accountId),
      isBusy: true,
      isLoading: false,
      error: '',
    );
    try {
      final next = await usecase.disconnect(owner, accountId);
      if (!_active(version)) return;
      state = state.copyWith(connections: next, isBusy: false);
      await refresh();
    } catch (error) {
      _failure(error, version);
    }
  }

  ExternalCalendarException _externalFailure(Object error) =>
      error is ExternalCalendarException
      ? error
      : const ExternalCalendarException(ExternalCalendarFailure.network);

  void _failure(Object error, int version) {
    if (!_active(version)) return;
    final failure = _externalFailure(error);
    state = state.copyWith(
      isLoading: false,
      isBusy: false,
      error: failure.message,
      failure: failure.kind,
    );
  }
}
