import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/services/android_widget_launch_uri_source.dart';
import 'package:memora/application/usecases/android_widget/watch_android_widget_launch_uri_usecase.dart';
import 'package:memora/presentation/notifiers/android_widget_launch_notifier.dart';

class _FakeAndroidWidgetLaunchUriSource
    implements AndroidWidgetLaunchUriSource {
  _FakeAndroidWidgetLaunchUriSource({this.initialUri});

  final Uri? initialUri;
  final controller = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get clickedUris => controller.stream;

  @override
  Future<Uri?> getInitialUri() async => initialUri;
}

void main() {
  group('AndroidWidgetLaunchNotifier', () {
    test('ウィジェットからの初回起動URIを保留し一度だけ取り出す', () async {
      final source = _FakeAndroidWidgetLaunchUriSource(
        initialUri: Uri.parse('memoraWidget://openTrip?tripId=trip-1'),
      );
      final container = ProviderContainer(
        overrides: [
          watchAndroidWidgetLaunchUriUsecaseProvider.overrideWithValue(
            WatchAndroidWidgetLaunchUriUsecase(source),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await source.controller.close();
      });

      container.read(androidWidgetLaunchNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      final notifier = container.read(
        androidWidgetLaunchNotifierProvider.notifier,
      );
      expect(
        container.read(androidWidgetLaunchNotifierProvider).pendingTripId,
        'trip-1',
      );
      expect(notifier.takePendingTripId(), 'trip-1');
      expect(notifier.takePendingTripId(), isNull);
    });

    test('起動済みアプリへのクリックURIを保留し不正なURIは無視する', () async {
      final source = _FakeAndroidWidgetLaunchUriSource();
      final container = ProviderContainer(
        overrides: [
          watchAndroidWidgetLaunchUriUsecaseProvider.overrideWithValue(
            WatchAndroidWidgetLaunchUriUsecase(source),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await source.controller.close();
      });

      container.read(androidWidgetLaunchNotifierProvider);
      source.controller.add(Uri.parse('memoraWidget://refresh'));
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(androidWidgetLaunchNotifierProvider).pendingTripId,
        isNull,
      );

      source.controller.add(Uri.parse('memoraWidget://openTrip?tripId=trip-2'));
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(androidWidgetLaunchNotifierProvider).pendingTripId,
        'trip-2',
      );
    });
  });
}
