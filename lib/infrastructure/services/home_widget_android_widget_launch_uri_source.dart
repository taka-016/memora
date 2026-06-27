import 'package:home_widget/home_widget.dart';
import 'package:memora/application/services/android_widget_launch_uri_source.dart';

class HomeWidgetAndroidWidgetLaunchUriSource
    implements AndroidWidgetLaunchUriSource {
  const HomeWidgetAndroidWidgetLaunchUriSource();

  @override
  Stream<Uri?> get clickedUris => HomeWidget.widgetClicked;

  @override
  Future<Uri?> getInitialUri() {
    return HomeWidget.initiallyLaunchedFromHomeWidget();
  }
}
