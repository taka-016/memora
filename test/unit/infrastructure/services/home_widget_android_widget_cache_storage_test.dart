import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
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

  test('古い世代を後から保存しても現世代のキャッシュを維持する', () async {
    const storage = HomeWidgetAndroidWidgetCacheStorage();
    expect(storage, isA<AndroidWidgetCacheGenerationStorage>());
    final oldCache = _cache(groupId: 'group-a', generation: 0);
    await storage.saveItineraryCacheForGeneration(oldCache);
    expect(await storage.loadItineraryCache(), oldCache);

    expect(await storage.advanceCacheGeneration(), 1);
    final currentCache = _cache(groupId: 'group-b', generation: 1);
    await storage.saveItineraryCacheForGeneration(currentCache);
    await storage.saveItineraryCacheForGeneration(oldCache);

    expect(await storage.loadItineraryCache(), currentCache);
  });

  test('既存キャッシュを次世代へ引き継いでから表示世代を切り替える', () async {
    const storage = HomeWidgetAndroidWidgetCacheStorage();
    final cache = _cache(groupId: 'group-a', generation: 0);
    await storage.saveItineraryCacheForGeneration(cache);

    expect(await storage.advanceCacheGeneration(cache: cache), 1);

    expect(
      await storage.loadItineraryCache(),
      _cache(groupId: 'group-a', generation: 1),
    );
  });
}

AndroidWidgetItineraryCacheDto _cache({
  required String groupId,
  required int generation,
}) {
  return AndroidWidgetItineraryCacheDto(
    version: 1,
    sourceMode: AppMode.offline,
    generation: generation,
    groupId: groupId,
    selectedItineraryDateId: null,
    lastUpdatedAt: DateTime(2026, 9, 13),
    itineraryDates: const [],
  );
}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}
