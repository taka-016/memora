import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/android_widget_launch_uri_source.dart';
import 'package:memora/infrastructure/services/home_widget_android_widget_launch_uri_source.dart';

final watchAndroidWidgetLaunchUriUsecaseProvider =
    Provider<WatchAndroidWidgetLaunchUriUsecase>((ref) {
      return const WatchAndroidWidgetLaunchUriUsecase(
        HomeWidgetAndroidWidgetLaunchUriSource(),
      );
    });

class WatchAndroidWidgetLaunchUriUsecase {
  const WatchAndroidWidgetLaunchUriUsecase(this._source);

  final AndroidWidgetLaunchUriSource _source;

  Future<Uri?> getInitialUri() {
    return _source.getInitialUri();
  }

  Stream<Uri?> get clickedUris => _source.clickedUris;
}
