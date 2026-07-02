import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/application/services/android_widget_toast_notifier.dart';
import 'package:memora/application/usecases/android_widget/android_widget_itinerary_cache_usecases.dart';

typedef RefreshAndroidWidgetCache =
    Future<void> Function({
      required String groupId,
      String? selectedItineraryDateId,
    });

typedef MoveAndroidWidgetItineraryDate =
    Future<bool> Function(AndroidWidgetItineraryDateMoveDirection direction);

typedef ShowAndroidWidgetToast =
    Future<void> Function(AndroidWidgetToastNotification notification);

class AndroidWidgetActionHandler {
  const AndroidWidgetActionHandler({
    required this._cacheStorage,
    required this._refreshCache,
    required this._moveDate,
    required this._showToast,
  });

  final AndroidWidgetCacheStorage _cacheStorage;
  final RefreshAndroidWidgetCache _refreshCache;
  final MoveAndroidWidgetItineraryDate _moveDate;
  final ShowAndroidWidgetToast _showToast;

  Future<void> handle(Uri? uri) async {
    switch (uri?.host) {
      case 'previous':
        await _move(AndroidWidgetItineraryDateMoveDirection.previous);
        break;
      case 'next':
        await _move(AndroidWidgetItineraryDateMoveDirection.next);
        break;
      case 'refresh':
        await _refresh();
        break;
      case 'recent':
        await _returnToRecent();
        break;
    }
  }

  Future<void> _refresh() async {
    final groupId = await _cacheStorage.getTargetGroupId();
    if (groupId == null) {
      await _cacheStorage.updateWidget();
      return;
    }
    final selectedItineraryDateId = await _cacheStorage
        .getSelectedItineraryDateId();
    try {
      await _refreshCache(
        groupId: groupId,
        selectedItineraryDateId: selectedItineraryDateId,
      );
    } catch (_) {
      await _showToastSafely(
        const AndroidWidgetToastNotification.error('更新に失敗しました'),
      );
      return;
    }
    await _showToastSafely(
      const AndroidWidgetToastNotification.success('更新しました。'),
    );
  }

  Future<void> _returnToRecent() async {
    final groupId = await _cacheStorage.getTargetGroupId();
    if (groupId == null) {
      await _cacheStorage.updateWidget();
      return;
    }
    try {
      await _refreshCache(groupId: groupId);
    } catch (_) {
      await _showMoveFailedToast();
    }
  }

  Future<void> _move(AndroidWidgetItineraryDateMoveDirection direction) async {
    try {
      final succeeded = await _moveDate(direction);
      if (succeeded) {
        return;
      }
    } catch (_) {
      await _showMoveFailedToast();
      return;
    }
    await _showMoveFailedToast();
  }

  Future<void> _showMoveFailedToast() async {
    await _showToastSafely(
      const AndroidWidgetToastNotification.error('切り替えに失敗しました'),
    );
  }

  Future<void> _showToastSafely(
    AndroidWidgetToastNotification notification,
  ) async {
    try {
      await _showToast(notification);
    } catch (_) {}
  }
}
