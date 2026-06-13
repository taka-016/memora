import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/application/services/android_widget_toast_notifier.dart';
import 'package:memora/application/usecases/android_widget/android_widget_action_handler.dart';

import '../../../../helpers/test_exception.dart';

void main() {
  group('AndroidWidgetActionHandler', () {
    test('更新成功後だけ更新完了Toastを表示する', () async {
      final storage = _FakeAndroidWidgetCacheStorage(
        targetGroupId: 'group-1',
        selectedItineraryDateId: 'trip-1_2026-05-24',
      );
      final toastNotifier = _FakeAndroidWidgetToastNotifier();
      final refreshCalls = <({String groupId, String? selectedId})>[];
      final handler = AndroidWidgetActionHandler(
        cacheStorage: storage,
        showToast: toastNotifier.show,
        refreshCache:
            ({required String groupId, String? selectedItineraryDateId}) async {
              refreshCalls.add((
                groupId: groupId,
                selectedId: selectedItineraryDateId,
              ));
            },
        moveDate: (_) async => true,
      );

      await handler.handle(Uri.parse('memoraWidget://refresh'));

      expect(refreshCalls, [
        (groupId: 'group-1', selectedId: 'trip-1_2026-05-24'),
      ]);
      expect(toastNotifier.notifications, [
        const AndroidWidgetToastNotification.success('更新しました。'),
      ]);
    });

    test('更新失敗時は更新失敗Toastを表示して例外を外へ出さない', () async {
      final storage = _FakeAndroidWidgetCacheStorage(targetGroupId: 'group-1');
      final toastNotifier = _FakeAndroidWidgetToastNotifier();
      final handler = AndroidWidgetActionHandler(
        cacheStorage: storage,
        showToast: toastNotifier.show,
        refreshCache:
            ({required String groupId, String? selectedItineraryDateId}) async {
              throw TestException('取得失敗');
            },
        moveDate: (_) async => true,
      );

      await expectLater(
        handler.handle(Uri.parse('memoraWidget://refresh')),
        completes,
      );

      expect(toastNotifier.notifications, [
        const AndroidWidgetToastNotification.error('更新に失敗しました'),
      ]);
    });

    test('更新成功後のToast失敗を更新失敗として扱わない', () async {
      final storage = _FakeAndroidWidgetCacheStorage(targetGroupId: 'group-1');
      final toastNotifier = _FakeAndroidWidgetToastNotifier(
        throwOnSuccessToast: true,
      );
      final handler = AndroidWidgetActionHandler(
        cacheStorage: storage,
        showToast: toastNotifier.show,
        refreshCache:
            ({
              required String groupId,
              String? selectedItineraryDateId,
            }) async {},
        moveDate: (_) async => true,
      );

      await expectLater(
        handler.handle(Uri.parse('memoraWidget://refresh')),
        completes,
      );

      expect(toastNotifier.notifications, [
        const AndroidWidgetToastNotification.success('更新しました。'),
      ]);
    });

    test('旅程日の切り替え失敗時は切り替え失敗Toastを表示する', () async {
      final storage = _FakeAndroidWidgetCacheStorage();
      final toastNotifier = _FakeAndroidWidgetToastNotifier();
      final handler = AndroidWidgetActionHandler(
        cacheStorage: storage,
        showToast: toastNotifier.show,
        refreshCache:
            ({
              required String groupId,
              String? selectedItineraryDateId,
            }) async {},
        moveDate: (_) async => false,
      );

      await handler.handle(Uri.parse('memoraWidget://previous'));

      expect(toastNotifier.notifications, [
        const AndroidWidgetToastNotification.error('切り替えに失敗しました'),
      ]);
    });
  });
}

class _FakeAndroidWidgetCacheStorage implements AndroidWidgetCacheStorage {
  _FakeAndroidWidgetCacheStorage({
    this.targetGroupId,
    this.selectedItineraryDateId,
  });

  String? targetGroupId;
  String? selectedItineraryDateId;
  int updateWidgetCount = 0;

  @override
  Future<void> clear() async {}

  @override
  Future<void> clearTargetGroupId() async {
    targetGroupId = null;
  }

  @override
  Future<String?> getSelectedItineraryDateId() async {
    return selectedItineraryDateId;
  }

  @override
  Future<String?> getTargetGroupId() async {
    return targetGroupId;
  }

  @override
  Future<void> saveItineraryCache(AndroidWidgetItineraryCacheDto cache) async {}

  @override
  Future<void> saveSelectedItineraryDateId(String? itineraryDateId) async {
    selectedItineraryDateId = itineraryDateId;
  }

  @override
  Future<void> saveTargetGroupId(String groupId) async {
    targetGroupId = groupId;
  }

  @override
  Future<void> updateWidget() async {
    updateWidgetCount += 1;
  }

  @override
  Future<AndroidWidgetItineraryCacheDto?> loadItineraryCache() async {
    return null;
  }
}

class _FakeAndroidWidgetToastNotifier {
  _FakeAndroidWidgetToastNotifier({this.throwOnSuccessToast = false});

  final bool throwOnSuccessToast;
  final notifications = <AndroidWidgetToastNotification>[];

  Future<void> show(AndroidWidgetToastNotification notification) async {
    notifications.add(notification);
    if (throwOnSuccessToast &&
        notification.type == AndroidWidgetToastNotificationType.success) {
      throw TestException('Toast失敗');
    }
  }
}
