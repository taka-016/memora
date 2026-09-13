import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:home_widget/home_widget.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:path_provider/path_provider.dart';

class HomeWidgetAndroidWidgetCacheStorage
    implements AndroidWidgetCacheStorage, AndroidWidgetCacheGenerationStorage {
  const HomeWidgetAndroidWidgetCacheStorage();

  static const targetGroupIdKey = 'memora_widget_target_group_id';
  static const selectedItineraryDateIdKey =
      'memora_widget_selected_itinerary_date_id';
  static const lastUpdatedAtKey = 'memora_widget_last_updated_at';
  static const cacheFileKey = 'memora_widget_itinerary_cache';
  static const cacheGenerationKey = 'memora_widget_cache_generation';
  static const _cacheGenerationLockFileName =
      'memora_widget_cache_generation.lock';
  static const qualifiedAndroidName =
      'com.example.memora.ItineraryWidgetReceiver';

  @override
  Future<String?> getTargetGroupId() async {
    final value = await HomeWidget.getWidgetData<String>(targetGroupIdKey);
    return value == null || value.isEmpty ? null : value;
  }

  @override
  Future<void> saveTargetGroupId(String groupId) async {
    await HomeWidget.saveWidgetData<String>(targetGroupIdKey, groupId);
  }

  @override
  Future<void> clearTargetGroupId() async {
    await HomeWidget.saveWidgetData<String>(targetGroupIdKey, '');
  }

  @override
  Future<String?> getSelectedItineraryDateId() async {
    final generation = await getCacheGeneration();
    final value =
        await HomeWidget.getWidgetData<String>(
          _generationKey(selectedItineraryDateIdKey, generation),
        ) ??
        (generation == 0
            ? await HomeWidget.getWidgetData<String>(selectedItineraryDateIdKey)
            : null);
    return value == null || value.isEmpty ? null : value;
  }

  @override
  Future<void> saveSelectedItineraryDateId(String? itineraryDateId) async {
    final generation = await getCacheGeneration();
    await HomeWidget.saveWidgetData<String>(
      _generationKey(selectedItineraryDateIdKey, generation),
      itineraryDateId ?? '',
    );
  }

  @override
  Future<AndroidWidgetItineraryCacheDto?> loadItineraryCache() async {
    final generation = await getCacheGeneration();
    final path =
        await HomeWidget.getWidgetData<String>(
          _generationKey(cacheFileKey, generation),
        ) ??
        (generation == 0
            ? await HomeWidget.getWidgetData<String>(cacheFileKey)
            : null);
    if (path == null || path.isEmpty) {
      return null;
    }
    final file = File(path);
    if (!await file.exists()) {
      return null;
    }
    final content = await file.readAsString();
    if (content.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(content) as Map<String, dynamic>;
    final cache = AndroidWidgetItineraryCacheDto.fromJson(decoded);
    return cache.generation == generation ? cache : null;
  }

  @override
  Future<void> saveItineraryCache(AndroidWidgetItineraryCacheDto cache) async {
    final generation = await getCacheGeneration();
    await saveItineraryCacheForGeneration(
      AndroidWidgetItineraryCacheDto(
        version: cache.version,
        sourceMode: cache.sourceMode,
        generation: generation,
        groupId: cache.groupId,
        selectedItineraryDateId: cache.selectedItineraryDateId,
        lastUpdatedAt: cache.lastUpdatedAt,
        itineraryDates: cache.itineraryDates,
      ),
    );
  }

  @override
  Future<void> saveItineraryCacheForGeneration(
    AndroidWidgetItineraryCacheDto cache,
  ) async {
    if (await getCacheGeneration() != cache.generation) {
      return;
    }
    await _writeItineraryCacheForGeneration(cache);
    if (await getCacheGeneration() != cache.generation) {
      await _deleteCacheForGeneration(cache.generation);
    }
  }

  Future<void> _writeItineraryCacheForGeneration(
    AndroidWidgetItineraryCacheDto cache,
  ) async {
    final json = jsonEncode(cache.toJson());
    final generation = cache.generation;
    await HomeWidget.saveFile(
      _generationKey(cacheFileKey, generation),
      Uint8List.fromList(utf8.encode(json)),
      extension: 'json',
    );
    await Future.wait([
      HomeWidget.saveWidgetData<String>(
        _generationKey(selectedItineraryDateIdKey, generation),
        cache.selectedItineraryDateId ?? '',
      ),
      HomeWidget.saveWidgetData<String>(
        _generationKey(lastUpdatedAtKey, generation),
        cache.lastUpdatedAt.toIso8601String(),
      ),
    ]);
  }

  @override
  Future<int> getCacheGeneration() async {
    return await HomeWidget.getWidgetData<int>(
          cacheGenerationKey,
          defaultValue: 0,
        ) ??
        0;
  }

  @override
  Future<int> advanceCacheGeneration({
    AndroidWidgetItineraryCacheDto? cache,
  }) async {
    return _withCacheGenerationLock(() async {
      final currentGeneration = await getCacheGeneration();
      final random = Random.secure();
      var generation = 0;
      while (generation == 0 || generation == currentGeneration) {
        generation = (random.nextInt(1 << 31) << 31) | random.nextInt(1 << 31);
      }
      if (cache != null) {
        await _writeItineraryCacheForGeneration(
          AndroidWidgetItineraryCacheDto(
            version: cache.version,
            sourceMode: cache.sourceMode,
            generation: generation,
            groupId: cache.groupId,
            selectedItineraryDateId: cache.selectedItineraryDateId,
            lastUpdatedAt: cache.lastUpdatedAt,
            itineraryDates: cache.itineraryDates,
          ),
        );
      }
      await HomeWidget.saveWidgetData<int>(cacheGenerationKey, generation);
      await _deleteCacheForGeneration(currentGeneration);
      return generation;
    });
  }

  Future<T> _withCacheGenerationLock<T>(Future<T> Function() action) async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    final lockFile = File('${directory.path}/$_cacheGenerationLockFileName');
    while (true) {
      try {
        lockFile.createSync(exclusive: true);
        lockFile.writeAsStringSync('$pid');
        break;
      } on FileSystemException {
        await _deleteStaleCacheGenerationLock(lockFile);
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }
    try {
      return await action();
    } finally {
      try {
        await lockFile.delete();
      } on FileSystemException {
        // 別処理が期限切れのロックを回収済みの場合は処理を継続する。
      }
    }
  }

  Future<void> _deleteStaleCacheGenerationLock(File lockFile) async {
    try {
      final ownerProcessId = int.tryParse(await lockFile.readAsString());
      final ownerIsRunning = ownerProcessId == null
          ? true
          : await Directory('/proc/$ownerProcessId').exists();
      if (!ownerIsRunning) {
        await lockFile.delete();
      }
    } on FileSystemException {
      // 作成直後や別処理による解放と競合した場合は次の取得で再確認する。
    }
  }

  Future<void> _deleteCacheForGeneration(int generation) async {
    final generationCacheKey = _generationKey(cacheFileKey, generation);
    final paths = <String>{};
    final generationPath = await HomeWidget.getWidgetData<String>(
      generationCacheKey,
    );
    if (generationPath != null && generationPath.isNotEmpty) {
      paths.add(generationPath);
    }
    if (generation == 0) {
      final legacyPath = await HomeWidget.getWidgetData<String>(cacheFileKey);
      if (legacyPath != null && legacyPath.isNotEmpty) {
        paths.add(legacyPath);
      }
    }
    await Future.wait([
      HomeWidget.saveWidgetData<String>(generationCacheKey, null),
      HomeWidget.saveWidgetData<String>(
        _generationKey(selectedItineraryDateIdKey, generation),
        null,
      ),
      HomeWidget.saveWidgetData<String>(
        _generationKey(lastUpdatedAtKey, generation),
        null,
      ),
      if (generation == 0) ...[
        HomeWidget.saveWidgetData<String>(cacheFileKey, null),
        HomeWidget.saveWidgetData<String>(selectedItineraryDateIdKey, null),
        HomeWidget.saveWidgetData<String>(lastUpdatedAtKey, null),
      ],
    ]);
    for (final path in paths) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  @override
  Future<void> clear() async {
    final generation = await advanceCacheGeneration();
    await Future.wait([
      clearTargetGroupId(),
      HomeWidget.saveWidgetData<String>(
        _generationKey(selectedItineraryDateIdKey, generation),
        '',
      ),
      HomeWidget.saveWidgetData<String>(lastUpdatedAtKey, ''),
      HomeWidget.saveWidgetData<String>(cacheFileKey, ''),
    ]);
  }

  @override
  Future<void> updateWidget() async {
    if (!Platform.isAndroid) {
      return;
    }
    await HomeWidget.updateWidget(qualifiedAndroidName: qualifiedAndroidName);
  }

  static String _generationKey(String key, int generation) {
    return '${key}_$generation';
  }
}
