import 'package:memora/application/services/android_widget_cache_storage.dart';

enum AndroidWidgetKind { itinerary, calendar }

class RefreshAndroidWidgetCachesUsecase {
  const RefreshAndroidWidgetCachesUsecase({
    required this.storage,
    required this.loadInstalledKinds,
    required this.refreshItinerary,
    required this.refreshCalendar,
  });

  final AndroidWidgetCacheStorage storage;
  final Future<Set<AndroidWidgetKind>> Function() loadInstalledKinds;
  final Future<void> Function(String groupId) refreshItinerary;
  final Future<void> Function(String groupId) refreshCalendar;

  Future<void> execute({Set<AndroidWidgetKind> kinds = const {
    AndroidWidgetKind.itinerary, AndroidWidgetKind.calendar,
  }}) async {
    final groupId = await storage.getTargetGroupId();
    if (groupId == null) return;
    final installed = await loadInstalledKinds();
    final targets = installed.intersection(kinds);
    Object? failure;
    StackTrace? failureStack;
    for (final kind in targets) {
      try {
        await (kind == AndroidWidgetKind.itinerary
            ? refreshItinerary(groupId)
            : refreshCalendar(groupId));
      } catch (error, stack) {
        failure ??= error;
        failureStack ??= stack;
      }
    }
    if (failure != null) Error.throwWithStackTrace(failure, failureStack!);
  }
}
