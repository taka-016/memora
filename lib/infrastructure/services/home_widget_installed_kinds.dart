import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:memora/application/usecases/android_widget/refresh_android_widget_caches_usecase.dart';

Future<Set<AndroidWidgetKind>> loadInstalledAndroidWidgetKinds() async {
  if (!Platform.isAndroid) return {};
  final widgets = await HomeWidget.getInstalledWidgets();
  final kinds = <AndroidWidgetKind>{};
  for (final widget in widgets) {
    switch (widget.androidClassName?.split('.').last) {
      case 'ItineraryWidgetReceiver':
      case 'ItineraryDarkWidgetReceiver':
        kinds.add(AndroidWidgetKind.itinerary);
      case 'CalendarWidgetReceiver':
      case 'CalendarDarkWidgetReceiver':
      case 'DailyCalendarWidgetReceiver':
      case 'DailyCalendarDarkWidgetReceiver':
        kinds.add(AndroidWidgetKind.calendar);
    }
  }
  return kinds;
}
