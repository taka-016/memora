import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/services/android_widget_launch_uri_source.dart';
import 'package:memora/application/services/combined_android_widget_launch_uri_source.dart';

class _Source implements AndroidWidgetLaunchUriSource {
  _Source(this.initial);
  final Uri? initial;
  final clicks = StreamController<Uri?>();
  @override
  Future<Uri?> getInitialUri() async => initial;
  @override
  Stream<Uri?> get clickedUris => clicks.stream;
}

void main() {
  test('通知の初回起動と両方のタップを渡し終了時に購読を解除する', () async {
    final notificationUri = Uri.parse(
      'memoraWidget://openCalendar?groupId=g&eventId=e',
    );
    final widget = _Source(null);
    final notification = _Source(notificationUri);
    addTearDown(widget.clicks.close);
    addTearDown(notification.clicks.close);
    final combined = CombinedAndroidWidgetLaunchUriSource([
      widget,
      notification,
    ]);
    expect(await combined.getInitialUri(), notificationUri);
    final received = <Uri?>[];
    final subscription = combined.clickedUris.listen(received.add);
    widget.clicks.add(Uri.parse('memoraWidget://openCalendar?create=true'));
    notification.clicks.add(notificationUri);
    await pumpEventQueue();
    expect(received.map((uri) => uri!.queryParameters), [
      containsPair('create', 'true'),
      containsPair('eventId', 'e'),
    ]);
    await subscription.cancel();
    expect(widget.clicks.hasListener, isFalse);
    expect(notification.clicks.hasListener, isFalse);
  });
}
