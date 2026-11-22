import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:memora/application/usecases/android_widget/android_widget_action_handler.dart';
import 'package:memora/composition_root/android_widget_composition_root.dart';

class AndroidWidgetInteractivityHandler {
  AndroidWidgetInteractivityHandler(this._handle);

  final Future<void> Function(Uri?) _handle;

  // HomeWidgetのWorkerはDart側の取得完了を待たない。
  bool _updatingCalendar = false;

  Future<void> call(Uri? uri) async {
    if (!isAutomaticCalendarWidgetRefresh(uri)) {
      await _handle(uri);
      return;
    }
    if (_updatingCalendar) return;
    _updatingCalendar = true;
    try {
      await _handle(uri);
    } finally {
      _updatingCalendar = false;
    }
  }
}

final _interactivityHandler = AndroidWidgetInteractivityHandler(
  _handleAndroidWidgetAction,
);

@pragma('vm:entry-point')
Future<void> androidWidgetInteractivityCallback(Uri? uri) =>
    _interactivityHandler(uri);

Future<void> _handleAndroidWidgetAction(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  await withAndroidWidgetDependencies(
    (refresh, handler, _) => handler.handle(uri),
  );
}

void registerAndroidWidgetInteractivityCallback() {
  HomeWidget.registerInteractivityCallback(androidWidgetInteractivityCallback);
}
