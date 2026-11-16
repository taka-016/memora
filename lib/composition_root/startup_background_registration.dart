class StartupBackgroundRegistration {
  StartupBackgroundRegistration({
    required this._loadRegistered,
    required this._markRegistered,
    required this._initialize,
    required this._registerNotifications,
    required this._loadWidgetInterval,
    required this._registerWidget,
  });

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
