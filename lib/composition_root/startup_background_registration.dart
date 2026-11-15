import 'dart:async';

class StartupBackgroundRegistration {
  StartupBackgroundRegistration({
    required Future<bool> Function(String task) loadRegistered,
    required Future<void> Function(String task) markRegistered,
    required Future<void> Function() initialize,
    required Future<void> Function() registerNotifications,
    required Future<Duration> Function() loadWidgetInterval,
    required Future<void> Function(Duration interval) registerWidget,
  }) : _loadRegistered = loadRegistered,
       _markRegistered = markRegistered,
       _initialize = initialize,
       _registerNotifications = registerNotifications,
       _loadWidgetInterval = loadWidgetInterval,
       _registerWidget = registerWidget;

  final Future<bool> Function(String task) _loadRegistered;
  final Future<void> Function(String task) _markRegistered;
  final Future<void> Function() _initialize;
  final Future<void> Function() _registerNotifications;
  final Future<Duration> Function() _loadWidgetInterval;
  final Future<void> Function(Duration interval) _registerWidget;
  Future<void>? _initialization;
  Future<void>? _widgetQueue;

  Future<void> _ensureInitialized() async {
    try {
      await (_initialization ??= _initialize());
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<void> registerWidget() {
    final result = _registerWidgetAfter(_widgetQueue);
    _widgetQueue = _ignoreFailure(result);
    return result;
  }

  Future<void> _ignoreFailure(Future<void> action) async {
    try {
      await action;
    } catch (_) {}
  }

  Future<void> _registerWidgetAfter(Future<void>? previous) async {
    if (previous != null) await previous;
    await _ensureInitialized();
    final interval = await _loadWidgetInterval();
    await _registerWidget(interval);
    await _markRegistered('widget');
  }

  Future<void> _registerNotificationTask() async {
    await _ensureInitialized();
    await _registerNotifications();
    await _markRegistered('notifications');
  }

  Future<void> start({
    required Future<void> Function() waitBeforeReregistration,
    required void Function(String message) onError,
  }) async {
    Future<void>? delay;
    Future<void> register(
      String task,
      String label,
      Future<void> Function() action,
    ) async {
      try {
        if (await _loadRegistered(task)) {
          await (delay ??= waitBeforeReregistration());
        }
        await action();
      } catch (_) {
        onError('$labelの定期バックグラウンド処理を登録できませんでした。次回起動時に再試行します。');
      }
    }

    await Future.wait([
      register('notifications', '通知', _registerNotificationTask),
      register('widget', 'ウィジェット', registerWidget),
    ]);
  }
}
