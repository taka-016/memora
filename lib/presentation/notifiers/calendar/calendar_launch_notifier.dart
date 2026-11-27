import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memora/application/dtos/calendar/calendar_launch_request_dto.dart';
import 'package:memora/composition_root/providers/calendar_launch_providers.dart';
import 'package:memora/core/app_logger.dart';

part 'calendar_launch_notifier.g.dart';

class CalendarLaunchState {
  const CalendarLaunchState({
    this.request,
    this.sequence = 0,
    this.isLoading = false,
  });
  final CalendarLaunchRequestDto? request;
  final int sequence;
  final bool isLoading;
}

@Riverpod(keepAlive: true)
class CalendarLaunchNotifier extends _$CalendarLaunchNotifier {
  int _version = 0;
  bool _reading = false;
  bool _readAgain = false;

  @override
  CalendarLaunchState build() {
    final usecase = ref.watch(watchCalendarLaunchUsecaseProvider);
    final subscription = usecase.changes.listen((_) => unawaited(_load()));
    ref.onDispose(() => unawaited(subscription.cancel()));
    unawaited(_load());
    return const CalendarLaunchState(isLoading: true);
  }

  Future<void> _load() async {
    if (!ref.mounted) return;
    if (_reading) {
      _readAgain = true;
      return;
    }
    _reading = true;
    try {
      do {
        _readAgain = false;
        final version = _version;
        CalendarLaunchRequestDto? request;
        try {
          request = await ref.read(watchCalendarLaunchUsecaseProvider).takePending();
        } catch (error, stackTrace) {
          logger.e('カレンダーの起動要求を取得できませんでした', error: error, stackTrace: stackTrace);
        }
        if (!ref.mounted) return;
        if (version == _version) {
          state = CalendarLaunchState(
            request: request ?? state.request,
            sequence: state.sequence + (request == null ? 0 : 1),
          );
        }
      } while (_readAgain);
    } finally {
      _reading = false;
    }
  }

  CalendarLaunchRequestDto? takeRequest() {
    final request = state.request;
    state = CalendarLaunchState(sequence: state.sequence);
    return request;
  }

  void cancelPendingLaunch() {
    _version++;
    state = CalendarLaunchState(sequence: state.sequence);
  }
}
