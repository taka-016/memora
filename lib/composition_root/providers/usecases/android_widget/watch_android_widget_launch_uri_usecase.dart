import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/android_widget_launch_uri_source.dart';
import 'package:memora/infrastructure/services/home_widget_android_widget_launch_uri_source.dart';
import 'package:memora/application/usecases/android_widget/watch_android_widget_launch_uri_usecase.dart';

final watchAndroidWidgetLaunchUriUsecaseProvider =
    Provider<WatchAndroidWidgetLaunchUriUsecase>((ref) {
      return const WatchAndroidWidgetLaunchUriUsecase(
        HomeWidgetAndroidWidgetLaunchUriSource(),
      );
    });
