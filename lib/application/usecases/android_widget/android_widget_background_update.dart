enum AndroidWidgetBackgroundUpdateStage {
  started,
  cacheUpdated,
  widgetUpdated,
  failed,
  completed,
}

typedef AndroidWidgetBackgroundUpdateStageRecorder = void Function(
  AndroidWidgetBackgroundUpdateStage stage,
  Object? error,
  StackTrace? stackTrace,
);

class AndroidWidgetBackgroundUpdateRunner {
  const AndroidWidgetBackgroundUpdateRunner({
    required this._refreshCache,
    required this._updateWidget,
    required this._showUpdateFailedNotification,
    required this._recordStage,
    required this._refreshTimeout,
    required this._widgetUpdateTimeout,
    required this._notificationTimeout,
  });

  final Future<void> Function() _refreshCache;
  final Future<void> Function() _updateWidget;
  final Future<void> Function() _showUpdateFailedNotification;
  final AndroidWidgetBackgroundUpdateStageRecorder _recordStage;
  final Duration _refreshTimeout;
  final Duration _widgetUpdateTimeout;
  final Duration _notificationTimeout;

  Future<bool> execute() async {
    _recordStage(AndroidWidgetBackgroundUpdateStage.started, null, null);
    try {
      await _refreshCache().timeout(_refreshTimeout);
      _recordStage(AndroidWidgetBackgroundUpdateStage.cacheUpdated, null, null);
      await _updateWidget().timeout(_widgetUpdateTimeout);
      _recordStage(
        AndroidWidgetBackgroundUpdateStage.widgetUpdated,
        null,
        null,
      );
    } catch (error, stackTrace) {
      _recordStage(
        AndroidWidgetBackgroundUpdateStage.failed,
        error,
        stackTrace,
      );
      await _runWithTimeoutIgnoringFailure(_updateWidget, _widgetUpdateTimeout);
      await _runWithTimeoutIgnoringFailure(
        _showUpdateFailedNotification,
        _notificationTimeout,
      );
    } finally {
      _recordStage(AndroidWidgetBackgroundUpdateStage.completed, null, null);
    }
    return true;
  }
}

class AndroidWidgetPeriodicUpdateRegistrar {
  const AndroidWidgetPeriodicUpdateRegistrar({
    required this._loadStartedAt,
    required this._loadCompletedAt,
    required this._cancelPeriodicTask,
    required this._registerPeriodicTask,
    required this._now,
    required this._staleAfter,
  });

  final Future<DateTime?> Function() _loadStartedAt;
  final Future<DateTime?> Function() _loadCompletedAt;
  final Future<void> Function() _cancelPeriodicTask;
  final Future<void> Function(Duration frequency) _registerPeriodicTask;
  final DateTime Function() _now;
  final Duration _staleAfter;

  Future<void> execute(Duration frequency) async {
    final timestamps = await Future.wait([
      _loadStartedAt(),
      _loadCompletedAt(),
    ]);
    final startedAt = timestamps[0];
    final completedAt = timestamps[1];
    if (_isStale(startedAt, completedAt)) {
      await _cancelPeriodicTask();
    }
    await _registerPeriodicTask(frequency);
  }

  bool _isStale(DateTime? startedAt, DateTime? completedAt) {
    return startedAt != null &&
        (completedAt == null || completedAt.isBefore(startedAt)) &&
        _now().difference(startedAt) >= _staleAfter;
  }
}

Future<void> _runWithTimeoutIgnoringFailure(
  Future<void> Function() operation,
  Duration timeout,
) async {
  try {
    await operation().timeout(timeout);
  } catch (_) {}
}
