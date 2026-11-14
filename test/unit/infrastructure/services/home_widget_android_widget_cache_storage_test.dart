import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:memora/infrastructure/services/home_widget_calendar_cache_storage.dart';

import 'package:flutter/services.dart';

import '../../../helpers/test_exception.dart';

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

  test('旅程取得中と失敗を選択日ごとに公開し再試行成功で解除する', () async {
    const storage = HomeWidgetAndroidWidgetCacheStorage();
    const selected = 'trip_2026-11-08';
    const key = 'memora_widget_itinerary_load_group_$selected';
    await expectLater(
      storage.trackItineraryLoading('group', selected, () async {
        expect(values[key], startsWith('loading:'));
        expect(values['memora_widget_itinerary_load_other_$selected'], isNull);
        throw TestException('旅程取得失敗');
      }, false),
      throwsA(isA<TestException>()),
    );
    expect(values[key], 'failed');
    await storage.trackItineraryLoading('group', selected, () async {
      expect(values[key], startsWith('loading:'));
    }, false);
    expect(values[key], isNull);
    await storage.trackItineraryLoading('group', null, () async {
      expect(
        values['memora_widget_itinerary_load_group_recent'],
        startsWith('loading:'),
      );
    }, false);
    expect(values['memora_widget_itinerary_load_group_recent'], isNull);
  });

  test('カレンダー取得中は月ごとに状態を公開し成功後に解除する', () async {
    const storage = HomeWidgetCalendarCacheStorage();
    final result = Completer<void>();
    final started = Completer<void>();
    final key = HomeWidgetCalendarCacheStorage.loadStateKey(
      'group',
      DateTime(2026, 11, 8),
    );
    final refresh = storage.refresh('group', DateTime(2026, 11, 8), () async {
      started.complete();
      await result.future;
    });
    await started.future;
    expect(values[key], startsWith('loading:'));
    expect(
      values[HomeWidgetCalendarCacheStorage.loadStateKey(
        'group',
        DateTime(2026, 12),
      )],
      isNull,
    );
    result.complete();
    await refresh;
    expect(values[key], isNull);
  });

  test('カレンダー取得失敗を公開し再試行で読み込み中へ戻す', () async {
    const storage = HomeWidgetCalendarCacheStorage();
    final date = DateTime(2026, 11);
    final key = HomeWidgetCalendarCacheStorage.loadStateKey('group', date);
    await expectLater(
      storage.refresh('group', date, () async {
        throw TestException('取得失敗');
      }),
      throwsA(isA<TestException>()),
    );
    expect(values[key], 'failed');
    await storage.refresh('group', date, () async {
      expect(values[key], startsWith('loading:'));
    });
    expect(values[key], isNull);
  });

  test('先行した取得の失敗で新しい取得の状態を上書きしない', () async {
    const storage = HomeWidgetCalendarCacheStorage();
    final date = DateTime(2026, 11);
    final first = Completer<void>();
    final second = Completer<void>();
    final firstStarted = Completer<void>();
    final secondStarted = Completer<void>();
    final oldRefresh = storage.refresh('group', date, () async {
      firstStarted.complete();
      await first.future;
      throw TestException('先行取得の失敗');
    });
    final oldFailure = expectLater(oldRefresh, throwsA(isA<TestException>()));
    await firstStarted.future;
    final newRefresh = storage.refresh('group', date, () async {
      secondStarted.complete();
      await second.future;
    });
    await secondStarted.future;
    first.complete();
    await oldFailure;
    final key = HomeWidgetCalendarCacheStorage.loadStateKey('group', date);
    expect(values[key], startsWith('loading:'));
    second.complete();
    await newRefresh;
    expect(values[key], isNull);
  });

  test('カレンダーの月と全予定をファイルで公開し対象解除時に削除する', () async {
    const calendar = HomeWidgetCalendarCacheStorage();
    final data = <String, Object?>{
      'lastUpdatedAt': '2026-11-11T12:00:00.000',
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
    expect(
      values[HomeWidgetAndroidWidgetCacheStorage.lastUpdatedAtKey],
      '2026-11-11T12:00:00.000',
    );
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

  test('利用者や表示対象が変わったら以前の月を結合しない', () async {
    const storage = HomeWidgetCalendarCacheStorage();
    for (final scope in ['online:a:g1', 'online:a:g2', 'online:b:g2']) {
      await storage.save({
        'cacheScope': scope,
        'sourceMode': 'online',
        'month': scope == 'online:a:g1' ? '2026-05-01' : '2026-11-01',
        'months': {if (scope == 'online:a:g1') '2026-05-01': {} else '2026-11-01': {}},
      });
      final path = values[HomeWidgetCalendarCacheStorage.cacheKey] as String;
      final saved = jsonDecode(await File(path).readAsString()) as Map;
      if (scope != 'online:a:g1') expect((saved['months'] as Map).keys, ['2026-11-01']);
    }
  });

  test('カレンダー更新は既存月を置き換え設定と選択日を維持する', () async {
    const storage = HomeWidgetCalendarCacheStorage();
    values[HomeWidgetCalendarCacheStorage.selectedDateKey] = '2026-11-03';
    values[HomeWidgetAndroidWidgetCacheStorage.targetGroupIdKey] = 'group';
    Map<String, Object?> month(String key) => {
      'sourceMode': 'offline',
      'groupId': 'group',
      'month': key,
      'months': {
        key: {'month': key, 'days': <Object?>[]},
      },
    };
    await storage.save(month('2026-05-01'));
    await storage.save(month('2026-11-01'), merge: false);
    final path = values[HomeWidgetCalendarCacheStorage.cacheKey] as String;
    final saved = jsonDecode(await File(path).readAsString()) as Map;
    expect((saved['months'] as Map).keys, ['2026-11-01']);
    expect(await storage.loadSelectedDate(), DateTime(2026, 11, 3));
    expect(
      values[HomeWidgetAndroidWidgetCacheStorage.targetGroupIdKey],
      'group',
    );
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

  test('公開時は渡された日付だけに置き換え古いキャッシュを残さない', () async {
    const storage = HomeWidgetAndroidWidgetCacheStorage();
    await storage.saveItineraryCache(cache([date('date-1'), date('date-2')]));
    await storage.saveItineraryCache(
      cache([date('date-2', name: '更新後の旅行'), date('date-3')]),
    );
    final loaded = (await storage.loadItineraryCache())!;
    expect(loaded.itineraryDates.map((date) => date.id), ['date-2', 'date-3']);
    expect(loaded.itineraryDates.first.tripName, '更新後の旅行');
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
      ['date-3'],
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
