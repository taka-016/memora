import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/infrastructure/services/home_widget_android_widget_cache_storage.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('home_widget');
  late Directory directory;
  late PathProviderPlatform previousPathProvider;
  late Map<String, Object?> values;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('memora-widget-cache-');
    previousPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(directory.path);
    values = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final arguments = call.arguments as Map<Object?, Object?>;
          final id = arguments['id'] as String?;
          switch (call.method) {
            case 'getWidgetData':
              return values[id] ?? arguments['defaultValue'];
            case 'saveWidgetData':
              values[id!] = arguments['data'];
              return true;
          }
          throw UnimplementedError(call.method);
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    PathProviderPlatform.instance = previousPathProvider;
    await directory.delete(recursive: true);
  });

  test('単一キャッシュを消去すると公開済みファイルも削除する', () async {
    const storage = HomeWidgetAndroidWidgetCacheStorage();
    await storage.saveItineraryCache(
      AndroidWidgetItineraryCacheDto(
        version: 1,
        sourceMode: AppMode.offline,
        groupId: 'group-1',
        selectedItineraryDateId: null,
        lastUpdatedAt: DateTime(2026, 9, 17),
        itineraryDates: const [],
      ),
    );
    final path = values[HomeWidgetAndroidWidgetCacheStorage.cacheFileKey]!;
    expect(File(path as String).existsSync(), isTrue);

    await storage.clear();

    expect(values[HomeWidgetAndroidWidgetCacheStorage.cacheFileKey], isNull);
    expect(File(path).existsSync(), isFalse);
  });

  test('選択日は別キーではなく公開済みキャッシュから取得する', () async {
    const storage = HomeWidgetAndroidWidgetCacheStorage();
    await storage.saveItineraryCache(
      AndroidWidgetItineraryCacheDto(
        version: 1,
        sourceMode: AppMode.offline,
        groupId: 'group-1',
        selectedItineraryDateId: 'date-new',
        lastUpdatedAt: DateTime(2026, 9, 18),
        itineraryDates: const [],
      ),
    );
    values[HomeWidgetAndroidWidgetCacheStorage.selectedItineraryDateIdKey] =
        'date-old';

    expect(await storage.getSelectedItineraryDateId(), 'date-new');
  });
}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}
