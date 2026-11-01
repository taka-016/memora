import 'dart:io';
import 'dart:convert';

import 'package:memora/infrastructure/services/home_widget_calendar_cache_storage.dart';

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

  test('カレンダーの月と全予定をファイルで公開し対象解除時に削除する', () async {
    const calendar = HomeWidgetCalendarCacheStorage();
    final data = <String, Object?>{
      'groupId': 'group',
      'sourceMode': 'offline',
      'months': {
        '2026-11-01': {'month': '2026-11-01', 'days': <Object?>[]},
      },
      'month': '2026-11-01',
      'days': [
        {
          'date': '2026-11-01',
          'events': [
            {'title': '家族旅行'},
          ],
        },
      ],
    };
    await calendar.save(data);
    final path = values[HomeWidgetCalendarCacheStorage.cacheKey] as String;
    expect(jsonDecode(await File(path).readAsString()), data);
    expect(await calendar.loadMonth(), DateTime(2026, 11));
    await const HomeWidgetAndroidWidgetCacheStorage().clear();
    expect(values[HomeWidgetCalendarCacheStorage.cacheKey], isNull);
    expect(File(path).existsSync(), isFalse);
  });

  test('カレンダーは取得済み月を結合し選択月に近い最大7か月を保持する', () async {
    const storage = HomeWidgetCalendarCacheStorage();
    values[HomeWidgetCalendarCacheStorage.selectedDateKey] = '2026-07-01';
    for (final firstMonth in [2, 5, 8]) {
      final months = <String, Object?>{};
      for (var month = firstMonth; month < firstMonth + 3; month++) {
        final key = '2026-${month.toString().padLeft(2, '0')}-01';
        months[key] = {'month': key, 'days': <Object?>[]};
      }
      await storage.save({
        'sourceMode': 'offline',
        'groupId': 'group',
        'month': months.keys.first,
        'months': months,
      });
    }
    final path = values[HomeWidgetCalendarCacheStorage.cacheKey] as String;
    final cache =
        jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
    expect((cache['months'] as Map).keys.toSet(), {
      for (var month = 4; month <= 10; month++)
        '2026-${month.toString().padLeft(2, '0')}-01',
    });
    expect(await storage.loadSelectedDate(), DateTime(2026, 7, 1));
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

  AndroidWidgetItineraryDateCacheDto date(String id, {String name = '旅行'}) =>
      AndroidWidgetItineraryDateCacheDto(
        id: id,
        tripId: 'trip',
        tripName: name,
        tripPeriodLabel: '',
        dateLabel: '',
        date: DateTime(2026, 11, 2),
        itineraryItems: const [],
      );

  AndroidWidgetItineraryCacheDto cache(
    List<AndroidWidgetItineraryDateCacheDto> dates, {
    String groupId = 'group',
    AppMode mode = AppMode.offline,
    List<String> ids = const ['date-1', 'date-2', 'date-3'],
  }) => AndroidWidgetItineraryCacheDto(
    version: 1,
    sourceMode: mode,
    groupId: groupId,
    selectedItineraryDateId: dates.firstOrNull?.id,
    lastUpdatedAt: DateTime(2026, 11, 2),
    itineraryDates: dates,
    itineraryDateIds: ids,
    recentItineraryDateId: ids.firstOrNull,
  );

  test('移動時に取得した日付を蓄積し同じ日付は新しい取得結果で更新する', () async {
    const storage = HomeWidgetAndroidWidgetCacheStorage();
    await storage.saveItineraryCache(cache([date('date-1'), date('date-2')]));
    await storage.saveItineraryCache(
      cache([date('date-2', name: '更新後の旅行'), date('date-3')]),
    );
    final loaded = (await storage.loadItineraryCache())!;
    expect(loaded.itineraryDates.map((date) => date.id), [
      'date-1',
      'date-2',
      'date-3',
    ]);
    expect(loaded.itineraryDates[1].tripName, '更新後の旅行');
  });

  for (final differentGroup in [false, true]) {
    test('${differentGroup ? 'グループ' : 'モード'}が違う以前のキャッシュは混ぜない', () async {
      const storage = HomeWidgetAndroidWidgetCacheStorage();
      await storage.saveItineraryCache(cache([date('date-1')]));
      await storage.saveItineraryCache(
        cache(
          [date('date-2')],
          groupId: differentGroup ? 'other' : 'group',
          mode: differentGroup ? AppMode.offline : AppMode.online,
        ),
      );
      expect(
        (await storage.loadItineraryCache())!.itineraryDates.map(
          (date) => date.id,
        ),
        ['date-2'],
      );
    });
  }

  test('削除済みの日付は以前のキャッシュから引き継がない', () async {
    const storage = HomeWidgetAndroidWidgetCacheStorage();
    await storage.saveItineraryCache(cache([date('date-1'), date('date-2')]));
    await storage.saveItineraryCache(
      cache([date('date-3')], ids: ['date-2', 'date-3']),
    );
    expect(
      (await storage.loadItineraryCache())!.itineraryDates.map(
        (date) => date.id,
      ),
      ['date-2', 'date-3'],
    );
  });

  test('ネイティブで選択した取得済みの日付を次の更新でも優先する', () async {
    const storage = HomeWidgetAndroidWidgetCacheStorage();
    await storage.saveItineraryCache(cache([date('date-1'), date('date-2')]));
    values[HomeWidgetAndroidWidgetCacheStorage.selectedItineraryDateIdKey] =
        'date-2';
    expect(await storage.getSelectedItineraryDateId(), 'date-2');
    await storage.saveItineraryCache(cache([date('date-1')]));
    expect(await storage.getSelectedItineraryDateId(), 'date-2');
  });

  test('ナビゲーションに存在しない別キーの選択日は使わない', () async {
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
