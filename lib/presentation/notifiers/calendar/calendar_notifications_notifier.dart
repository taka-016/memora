import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memora/application/services/calendar/calendar_notification_gateway.dart';
import 'package:memora/composition_root/providers/calendar_notification_providers.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';
import 'package:memora/presentation/notifiers/backup/offline_backup_notifier.dart';
part 'calendar_notifications_notifier.g.dart';

class CalendarNotificationsState {
  const CalendarNotificationsState({this.status, this.isSyncing = false});
  final CalendarNotificationStatus? status;
  final bool isSyncing;
}

@Riverpod(keepAlive: true)
class CalendarNotificationsNotifier extends _$CalendarNotificationsNotifier {
  StreamSubscription<void>? _subscription;
  bool _running = false;
  bool _again = false;

  @override
  CalendarNotificationsState build() {
    if (!ref.watch(calendarNotificationsSupportedProvider)) {
      return const CalendarNotificationsState(
        status: CalendarNotificationStatus.denied,
      );
    }
    ref.listen(currentMemberNotifierProvider, (_, next) {
      if (next.status != CurrentMemberStatus.loading) {
        _watch();
        unawaited(refresh());
      }
    });
    ref.listen(offlineBackupNotifierProvider, (previous, next) {
      if (previous?.isRestoring == true && !next.isWorking) {
        unawaited(refresh());
      }
    });
    final timer = Timer.periodic(const Duration(hours: 1), (_) {
      _watch();
      unawaited(refresh());
    });
    ref.onDispose(() {
      timer.cancel();
      unawaited(_subscription?.cancel());
    });
    Future.microtask(() {
      if (!ref.mounted) return;
      _watch();
      unawaited(refresh());
    });
    return const CalendarNotificationsState(isSyncing: true);
  }

  void _watch() {
    unawaited(_subscription?.cancel());
    _subscription = ref
        .read(calendarNotificationSourceProvider)
        .changes()
        .listen(
          (_) {
            unawaited(refresh());
          },
          onError: (Object _, StackTrace stack) {
            if (ref.mounted) {
              state = const CalendarNotificationsState(
                status: CalendarNotificationStatus.failed,
              );
            }
          },
        );
  }

  Future<void> refresh() async {
    if (!ref.read(calendarNotificationsSupportedProvider)) return;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      do {
        _again = false;
        if (!ref.mounted) return;
        state = CalendarNotificationsState(
          status: state.status,
          isSyncing: true,
        );
        final result = await ref
            .read(synchronizeCalendarNotificationsUsecaseProvider)
            .execute();
        if (!ref.mounted) return;
        state = CalendarNotificationsState(status: result);
      } while (_again);
    } finally {
      _running = false;
    }
  }

  Future<void> requestPermission() async {
    try {
      await ref.read(calendarNotificationGatewayProvider).requestPermission();
      await refresh();
    } catch (_) {
      if (ref.mounted) {
        state = const CalendarNotificationsState(
          status: CalendarNotificationStatus.failed,
        );
      }
    }
  }
}
