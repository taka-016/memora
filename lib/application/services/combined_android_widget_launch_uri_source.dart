import 'dart:async';
import 'package:memora/application/services/android_widget_launch_uri_source.dart';

class CombinedAndroidWidgetLaunchUriSource implements AndroidWidgetLaunchUriSource {
  const CombinedAndroidWidgetLaunchUriSource(this.sources);
  final List<AndroidWidgetLaunchUriSource> sources;
  @override
  Future<Uri?> getInitialUri() async {
    for (final source in sources) {
      final uri = await source.getInitialUri();
      if (uri != null) return uri;
    }
    return null;
  }
  @override
  Stream<Uri?> get clickedUris => Stream.multi((controller) {
    final subscriptions = [for (final source in sources) source.clickedUris.listen(controller.add, onError: controller.addError)];
    controller.onCancel = () async {
      for (final subscription in subscriptions) { await subscription.cancel(); }
    };
  });
}
