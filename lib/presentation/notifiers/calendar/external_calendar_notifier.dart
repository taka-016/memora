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
      final connection = await usecase.restore(owner);
      if (!_active(version)) return;
      state = state.copyWith(connection: connection, isLoading: false);
      if (connection != null) await refresh();
    } catch (error) {
      _failure(error, version);
    }
  }

  Future<void> setPeriod(DateTime day) async {
    final month = DateTime(day.year, day.month);
    if (state.month == month) return;
    if (!state.isBusy && state.connection != null) _version++;
    state = state.copyWith(
      month: month,
      events: [],
      isLoading: false,
      isStale: false,
      error: '',
    );
    if (!state.isBusy) await refresh();
  }

  Future<void> connect() async {
    final owner = _owner;
    if (owner == null || state.isBusy) return;
    final usecase = ref.read(externalCalendarUsecaseProvider)!;
    final version = ++_version;
    state = ExternalCalendarState(month: state.month, isBusy: true);
    try {
      final connection = await usecase.connect(owner);
      if (!_active(version)) return;
      state = state.copyWith(connection: connection, isBusy: false);
      await refresh();
    } catch (error) {
      _failure(error, version);
    }
  }

  Future<void> selectCalendars(Set<String> ids) async {
    final owner = _owner;
    final connection = state.connection;
    if (owner == null || connection == null || state.isBusy) return;
    final usecase = ref.read(externalCalendarUsecaseProvider)!;
    final version = ++_version;
    state = state.copyWith(isBusy: true, isLoading: false, error: '');
    try {
      final next = await usecase.select(owner, connection, ids);
      if (!_active(version)) return;
      state = state.copyWith(
        connection: next,
        events: [],
        isStale: false,
        isBusy: false,
      );
      await refresh();
    } catch (error) {
      _failure(error, version);
    }
  }

  Future<void> refresh() async {
    final connection = state.connection;
    if (_owner == null || connection == null || state.isBusy) return;
    final usecase = ref.read(externalCalendarUsecaseProvider)!;
    final version = ++_version;
    final month = state.month;
    state = state.copyWith(isLoading: true, error: '');
    try {
      final calendars = await usecase.calendars(connection.account.id);
      if (!_active(version)) return;
      state = state.copyWith(calendars: calendars);
      if (connection.calendarIds.any(
        (id) => !calendars.any((calendar) => calendar.id == id),
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
              connection.account.id,
              selected,
              DateTime(month.year, month.month, -6),
              DateTime(month.year, month.month + 1, 8),
            );
      if (!_active(version)) return;
      state = state.copyWith(
        events: events,
        isLoading: false,
        isStale: false,
        error: '',
      );
    } catch (error) {
      _failure(error, version);
    }
  }

  Future<void> disconnect() async {
    final owner = _owner;
    if (owner == null || state.isBusy) return;
    final usecase = ref.read(externalCalendarUsecaseProvider)!;
    final version = ++_version;
    state = ExternalCalendarState(month: state.month, isBusy: true);
    try {
      await usecase.disconnect(owner);
      if (_active(version)) state = state.copyWith(isBusy: false);
    } catch (error) {
      _failure(error, version);
    }
  }

  void _failure(Object error, int version) {
    if (!_active(version)) return;
    final failure = error is ExternalCalendarException
        ? error
        : const ExternalCalendarException(ExternalCalendarFailure.network);
    state = state.copyWith(
      isLoading: false,
      isBusy: false,
      isStale: state.events.isNotEmpty,
      error: failure.message,
      failure: failure.kind,
    );
  }
}
