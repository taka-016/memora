import 'package:memora/application/services/android_widget_launch_uri_source.dart';

class WatchAndroidWidgetLaunchUriUsecase {
  const WatchAndroidWidgetLaunchUriUsecase(this._source);

  final AndroidWidgetLaunchUriSource _source;

  Future<Uri?> getInitialUri() {
    return _source.getInitialUri();
  }

  Stream<Uri?> get clickedUris => _source.clickedUris;
}
