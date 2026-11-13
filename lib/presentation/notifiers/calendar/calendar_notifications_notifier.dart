import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memora/application/services/calendar/calendar_notification_gateway.dart';
import 'package:memora/composition_root/providers/calendar_notification_providers.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';
import 'package:memora/presentation/notifiers/backup/offline_backup_notifier.dart';
part 'calendar_notifications_notifier.g.dart';

class CalendarNotificationsState {
  const CalendarNotificationsState({
    this.status,
    this.isSyncing = false,
    this.isSuspended = false,
  });
  final CalendarNotificationStatus? status;
  final bool isSyncing;
  final bool isSuspended;
}

@Riverpod(keepAlive: true)
class CalendarNotificationsNotifier extends _$CalendarNotificationsNotifier {
  StreamSubscription<void>? _subscription;
  bool _running = false;
  bool _again = false;
  bool _openingSettings = false;

  @override
  CalendarNotificationsState build() {
    if (!ref.watch(calendarNotificationsSupportedProvider)) {
      return const CalendarNotificationsState(
        status: CalendarNotificationStatus.denied,
      );
    }
    ref.listen(currentMemberNotifierProvider, (_, next) {
      unawaited(_subscription?.cancel());
      _subscription = null;
      unawaited(refresh());
    });
    ref.listen(offlineBackupNotifierProvider, (previous, next) {
      if (previous?.isRestoring == true && !next.isWorking) {
        unawaited(refresh());
      }
    });
    final timer = Timer.periodic(const Duration(hours: 1), (_) {
      unawaited(refresh());
    });
    ref.onDispose(() {
      timer.cancel();
      unawaited(_subscription?.cancel());
    });
    Future.microtask(() {
      if (!ref.mounted) return;
      unawaited(refresh());
    });
    return const CalendarNotificationsState(isSyncing: true);
  }

  void _watch() {
    if (state.isSuspended || _subscription != null) return;
    final member = ref.read(currentMemberNotifierProvider);
    if (member.status != CurrentMemberStatus.loaded || member.member == null) {
      return;
    }
    _subscription = ref
        .read(calendarNotificationSourceProvider)
        .changes()
        .listen(
          (_) {
            unawaited(refresh());
          },
          onError: (Object _, StackTrace stack) {
            if (ref.mounted) {
              state = CalendarNotificationsState(
                isSuspended: state.isSuspended,
                status: CalendarNotificationStatus.failed,
              );
            }
          },
        );
  }

  Future<void> setSuspended(bool suspended) async {
    if (state.isSuspended == suspended) return;
    state = CalendarNotificationsState(
      status: state.status,
      isSyncing: suspended ? false : state.isSyncing,
      isSuspended: suspended,
    );
    if (suspended) {
      final subscription = _subscription;
      _subscription = null;
      await subscription?.cancel();
    } else {
      await refresh();
    }
  }

  Future<void> retry() async {
    if (!ref.read(calendarNotificationsSupportedProvider)) return;
    await _subscription?.cancel();
    _subscription = null;
    await refresh();
  }

  Future<void> refresh() async {
    if (state.isSuspended ||
        !ref.read(calendarNotificationsSupportedProvider)) {
      return;
    }
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      do {
        _again = false;
        if (!ref.mounted || state.isSuspended) return;
        state = CalendarNotificationsState(
          isSuspended: state.isSuspended,
          status: state.status,
          isSyncing: true,
        );
        CalendarNotificationStatus result;
        try {
          final member = ref.read(currentMemberNotifierProvider);
          if (member.status != CurrentMemberStatus.loaded ||
              member.member == null) {
            await ref.read(calendarNotificationGatewayProvider).replace([]);
            result = CalendarNotificationStatus.ready;
          } else {
            final enabled = await ref
                .read(calendarNotificationGatewayProvider)
                .isEnabled();
            if (!ref.mounted) return;
            if (enabled) {
              _watch();
            } else {
              await _subscription?.cancel();
              _subscription = null;
            }
            if (!ref.mounted || state.isSuspended) return;
            result = await ref
                .read(synchronizeCalendarNotificationsUsecaseProvider)
                .execute();
          }
        } catch (_) {
          result = CalendarNotificationStatus.failed;
        }
        if (!ref.mounted || state.isSuspended) return;
        state = CalendarNotificationsState(
          isSuspended: state.isSuspended,
          status: result,
          isSyncing: _openingSettings,
        );
      } while (_again);
    } finally {
      _running = false;
    }
  }

  Future<void> openNotificationSettings() async {
    if (_openingSettings) return;
    _openingSettings = true;
    state = CalendarNotificationsState(
      isSuspended: state.isSuspended,
      status: state.status,
      isSyncing: true,
    );
    try {
      final opened = await ref
          .read(calendarNotificationGatewayProvider)
          .openNotificationSettings();
      if (ref.mounted) {
        state = CalendarNotificationsState(
          isSuspended: state.isSuspended,
          status: opened ? state.status : CalendarNotificationStatus.failed,
        );
      }
    } catch (_) {
      if (ref.mounted) {
        state = CalendarNotificationsState(
          isSuspended: state.isSuspended,
          status: CalendarNotificationStatus.failed,
        );
      }
    } finally {
      _openingSettings = false;
      if (ref.mounted) {
        state = CalendarNotificationsState(
          isSuspended: state.isSuspended,
          status: state.status,
          isSyncing: _running,
        );
      }
    }
  }

  Future<void> requestPermission() async {
    try {
      await ref.read(calendarNotificationGatewayProvider).requestPermission();
      await refresh();
    } catch (_) {
      if (ref.mounted) {
        state = CalendarNotificationsState(
          isSuspended: state.isSuspended,
          status: CalendarNotificationStatus.failed,
        );
      }
    }
  }
}
