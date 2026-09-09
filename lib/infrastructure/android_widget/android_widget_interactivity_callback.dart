import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:memora/composition_root/android_widget_composition_root.dart';

@pragma('vm:entry-point')
Future<void> androidWidgetInteractivityCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  await withAndroidWidgetDependencies(
    (refresh, handler) => handler.handle(uri),
  );
}

void registerAndroidWidgetInteractivityCallback() {
  HomeWidget.registerInteractivityCallback(androidWidgetInteractivityCallback);
}
