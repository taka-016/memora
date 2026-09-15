import 'dart:async';
import 'dart:convert';
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
  late int generationSaveCount;
  Future<void> Function(int saveCount)? beforeGenerationSave;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('memora-widget-cache-');
    previousPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(directory.path);
    values = {};
    generationSaveCount = 0;
    beforeGenerationSave = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final arguments = call.arguments as Map<Object?, Object?>;
          final id = arguments['id'] as String?;
          switch (call.method) {
            case 'getWidgetData':
              return values[id] ?? arguments['defaultValue'];
            case 'saveWidgetData':
              if (id ==
                  HomeWidgetAndroidWidgetCacheStorage.cacheGenerationKey) {
                generationSaveCount += 1;
                await beforeGenerationSave?.call(generationSaveCount);
              }
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
    final oldCachePath = values['memora_widget_itinerary_cache_0']! as String;

    final generation = await storage.advanceCacheGeneration();
    expect(generation, isNot(0));
    expect(values['memora_widget_itinerary_cache_0'], isNull);
    expect(File(oldCachePath).existsSync(), isFalse);
    final currentCache = _cache(groupId: 'group-b', generation: generation);
    await storage.saveItineraryCacheForGeneration(currentCache);
    await storage.saveItineraryCacheForGeneration(oldCache);

    expect(await storage.loadItineraryCache(), currentCache);
    expect(values['memora_widget_itinerary_cache_0'], isNull);
  });

  test('削除直前に消えた旧世代ファイルを成功扱いにする', () async {
    late String oldCachePath;
    final deletedFile = _DeletedDuringCleanupFile();
    final storage = HomeWidgetAndroidWidgetCacheStorage.withFileFactory(
      (path) => path == oldCachePath ? deletedFile : File(path),
    );
    final oldCache = _cache(groupId: 'group-a', generation: 0);
    await storage.saveItineraryCacheForGeneration(oldCache);
    oldCachePath = values['memora_widget_itinerary_cache_0']! as String;

    final generation = await storage.advanceCacheGeneration();

    expect(generation, isNot(0));
    expect(await storage.getCacheGeneration(), generation);
  });

  test('既存キャッシュを次世代へ引き継いでから表示世代を切り替える', () async {
    const storage = HomeWidgetAndroidWidgetCacheStorage();
    final cache = _cache(groupId: 'group-a', generation: 0);
    await storage.saveItineraryCacheForGeneration(cache);

    final generation = await storage.advanceCacheGeneration(
      updateCache: (currentCache) => currentCache,
    );

    expect(
      await storage.loadItineraryCache(),
      _cache(groupId: 'group-a', generation: generation),
    );
  });

  test('並行する世代更新を直列化して後発の世代を現世代にする', () async {
    const storage = HomeWidgetAndroidWidgetCacheStorage();
    final firstSaveStarted = Completer<void>();
    final releaseFirstSave = Completer<void>();
    final secondSaveStarted = Completer<void>();
    beforeGenerationSave = (saveCount) async {
      if (saveCount == 1) {
        firstSaveStarted.complete();
        await releaseFirstSave.future;
      } else if (saveCount == 2) {
        secondSaveStarted.complete();
      }
    };

    final firstAdvance = storage.advanceCacheGeneration();
    await firstSaveStarted.future;
    final secondAdvance = storage.advanceCacheGeneration();

    final secondStartedBeforeRelease = await Future.any([
      secondSaveStarted.future.then((_) => true),
      Future<void>.delayed(const Duration(milliseconds: 50)).then((_) => false),
    ]);
    releaseFirstSave.complete();
    await firstAdvance;
    final secondGeneration = await secondAdvance;
    expect(secondStartedBeforeRelease, isFalse);
    expect(await storage.getCacheGeneration(), secondGeneration);
  });

  test('世代更新関数へロック内で読み取った現世代のキャッシュを渡す', () async {
    const storage = HomeWidgetAndroidWidgetCacheStorage();
    final initialCache = _cache(groupId: 'group-a', generation: 0);
    await storage.saveItineraryCacheForGeneration(initialCache);
    final latestGeneration = await storage.advanceCacheGeneration(
      updateCache: (currentCache) => currentCache,
    );
    await storage.saveItineraryCacheForGeneration(
      _cache(groupId: 'group-b', generation: latestGeneration),
    );

    AndroidWidgetItineraryCacheDto? receivedCache;
    await storage.advanceCacheGeneration(
      updateCache: (currentCache) {
        receivedCache = currentCache;
        return currentCache;
      },
    );

    expect(receivedCache?.groupId, 'group-b');
    expect((await storage.loadItineraryCache())?.groupId, 'group-b');
  });

  test('所有者情報が空のロックファイルを回収して世代を更新する', () async {
    const storage = HomeWidgetAndroidWidgetCacheStorage();
    final lockFile = File(
      '${directory.path}/memora_widget_cache_generation.lock',
    );
    await lockFile.create();

    final advance = storage.advanceCacheGeneration();
    Object? timeoutError;
    try {
      await advance.timeout(const Duration(milliseconds: 500));
    } on Object catch (error) {
      timeoutError = error;
      await lockFile.delete();
      await advance;
    }

    expect(timeoutError, isNull);
    expect(await storage.getCacheGeneration(), isNot(0));
  });

  test('別プロセスのロックが解放されるまで待機して世代を更新する', () async {
    const storage = HomeWidgetAndroidWidgetCacheStorage();
    final lockPath = '${directory.path}/memora_widget_cache_generation.lock';
    final script = File('${directory.path}/hold_lock.dart');
    await script.writeAsString('''
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> arguments) async {
  final lock = Link(arguments.single);
  await lock.create('\$pid-child');
  stdout.writeln('locked');
  await stdin.transform(utf8.decoder).transform(const LineSplitter()).first;
  await lock.delete();
}
''');
    final process = await Process.start('dart', [script.path, lockPath]);
    expect(
      await process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .firstWhere((line) => line == 'locked'),
      'locked',
    );

    final advance = storage.advanceCacheGeneration();
    final resultBeforeRelease = await Future.any<Object?>([
      advance.then<Object?>(
        (_) => 'completed',
        onError: (Object error) => error,
      ),
      Future<void>.delayed(const Duration(milliseconds: 500))
          .then<Object?>((_) => 'waiting'),
    ]);
    process.stdin.writeln('release');
    await process.stdin.flush();
    await process.stdin.close();
    await process.exitCode;
    if (resultBeforeRelease == 'waiting') {
      await advance;
    }

    expect(resultBeforeRelease, 'waiting');
    expect(await storage.getCacheGeneration(), isNot(0));
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

final class _DeletedDuringCleanupFile implements File {
  var _exists = true;

  @override
  String get path => '削除済みの旧世代キャッシュ';

  @override
  Future<bool> exists() async => _exists;

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    _exists = false;
    throw FileSystemException(
      '別処理が先に削除しました',
      path,
      const OSError('No such file or directory', 2),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
