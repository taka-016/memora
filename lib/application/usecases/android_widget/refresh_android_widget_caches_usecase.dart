enum AndroidWidgetKind { itinerary, calendar }

class RefreshAndroidWidgetCachesUsecase {
  const RefreshAndroidWidgetCachesUsecase({
    required this.loadTargetGroupId,
    required this.loadInstalledKinds,
    required this.refreshItinerary,
    required this.refreshCalendar,
  });

  final Future<String?> Function() loadTargetGroupId;
  final Future<Set<AndroidWidgetKind>> Function() loadInstalledKinds;
  final Future<void> Function(String groupId) refreshItinerary;
  final Future<void> Function(String groupId) refreshCalendar;

  Future<void> execute({
    Set<AndroidWidgetKind> kinds = const {
      AndroidWidgetKind.itinerary,
      AndroidWidgetKind.calendar,
    },
  }) async {
    final installed = await loadInstalledKinds();
    final targets = installed.intersection(kinds);
    if (targets.isEmpty) return;
    final groupId = await loadTargetGroupId();

    Object? failure;
    StackTrace? failureStack;
    for (final kind in targets) {
      if (kind == AndroidWidgetKind.itinerary && groupId == null) continue;
      try {
        await (kind == AndroidWidgetKind.itinerary
            ? refreshItinerary(groupId!)
            : refreshCalendar(groupId ?? ''));
      } catch (error, stack) {
        failure ??= error;
        failureStack ??= stack;
      }
    }
    if (failure != null) Error.throwWithStackTrace(failure, failureStack!);
  }
}
