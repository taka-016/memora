import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:memora/application/usecases/android_widget/refresh_android_widget_caches_usecase.dart';

Future<Set<AndroidWidgetKind>> loadInstalledAndroidWidgetKinds() async {
  if (!Platform.isAndroid) return {};
  final widgets = await HomeWidget.getInstalledWidgets();
  return {for (final widget in widgets) ?_widgetKind(widget)};
}

Future<List<int>> loadInstalledAndroidCalendarWidgetIds() async {
  final widgets = await HomeWidget.getInstalledWidgets();
  return [
    for (final widget in widgets)
      if (_widgetKind(widget) == AndroidWidgetKind.calendar)
        ?widget.androidWidgetId,
  ];
}

AndroidWidgetKind? _widgetKind(HomeWidgetInfo widget) =>
    switch (widget.androidClassName?.split('.').last) {
      'ItineraryWidgetReceiver' ||
      'ItineraryDarkWidgetReceiver' => AndroidWidgetKind.itinerary,
      'CalendarWidgetReceiver' ||
      'CalendarDarkWidgetReceiver' ||
      'DailyCalendarWidgetReceiver' ||
      'DailyCalendarDarkWidgetReceiver' => AndroidWidgetKind.calendar,
      _ => null,
    };
