import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/application/exceptions/external_calendar_exception.dart';
import 'package:memora/application/queries/calendar/external_calendar_query_service.dart';
import 'package:memora/application/services/calendar/device_calendar_access_service.dart';
import 'package:memora/application/services/calendar/external_calendar_settings_storage.dart';
import 'package:memora/application/usecases/calendar/external_calendar_usecase.dart';
import 'package:memora/composition_root/providers/external_calendar_providers.dart';
import 'package:memora/presentation/notifiers/calendar/external_calendar_notifier.dart';

@GenerateNiceMocks([
  MockSpec<ExternalCalendarQueryService>(),
  MockSpec<DeviceCalendarAccessService>(),
  MockSpec<ExternalCalendarSettingsStorage>(),
])
import 'external_calendar_notifier_test.mocks.dart';

void main() {
  const first = ExternalCalendarAccount(id: 'first', name: 'first@example.com');
  const second = ExternalCalendarAccount(
    id: 'second',
    name: 'second@example.com',
  );
  const calendar = ExternalCalendarDto(id: '1', name: '個人');
  final connection = ExternalCalendarConnection(
    account: first,
    calendarIds: {'1'},
  );
  final secondConnection = ExternalCalendarConnection(
    account: second,
    calendarIds: {'1'},
  );
  ExternalCalendarEventDto event(String account) => ExternalCalendarEventDto(
    accountId: account,
    id: 'event',
    calendarId: '1',
    calendarName: '個人',
    title: '$accountの予定',
    startDateTime: DateTime(2026, 11, 1),
    endDateTime: DateTime(2026, 11, 1, 1),
    isAllDay: false,
  );
  late MockExternalCalendarQueryService query;
  late MockDeviceCalendarAccessService access;
  late MockExternalCalendarSettingsStorage storage;
  late ProviderContainer container;
  late ExternalCalendarNotifier notifier;
  late List<ExternalCalendarConnection> saved;
  late StreamController<void> changes;
  late int widgetUpdates;

  setUp(() {
    query = MockExternalCalendarQueryService();
    access = MockDeviceCalendarAccessService();
    storage = MockExternalCalendarSettingsStorage();
    saved = [connection];
    widgetUpdates = 0;
    changes = StreamController<void>.broadcast(sync: true);
    when(access.hasReadPermission()).thenAnswer((_) async => true);
    when(access.requestReadPermission()).thenAnswer((_) async => true);
    when(query.changes).thenAnswer((_) => changes.stream);
    when(query.accounts()).thenAnswer((_) async => [first, second]);
    when(query.calendars(any)).thenAnswer((_) async => [calendar]);
    when(query.events(any, any, any, any)).thenAnswer(
      (call) async => [event(call.positionalArguments.first as String)],
    );
    when(storage.load('owner')).thenAnswer((_) async => saved);
    when(storage.save('owner', any)).thenAnswer((call) async {
      saved = List<ExternalCalendarConnection>.from(
        call.positionalArguments[1] as List,
      );
    });
    container = ProviderContainer(
      overrides: [
        externalCalendarWidgetRefreshProvider.overrideWithValue(() async {
          widgetUpdates++;
        }),
        externalCalendarSupportedProvider.overrideWithValue(true),
        externalCalendarOwnerProvider.overrideWithValue('owner'),
        externalCalendarUsecaseProvider.overrideWithValue(
          ExternalCalendarUsecase(access, storage, query),
        ),
      ],
    );
    container.listen(externalCalendarNotifierProvider, (_, _) {});
    notifier = container.read(externalCalendarNotifierProvider.notifier);
    addTearDown(() async {
      container.dispose();
      await changes.close();
    });
  });

  test('未許可の起動時は要求画面や端末データを開かない', () async {
    when(access.hasReadPermission()).thenAnswer((_) async => false);
    await notifier.initialize();
    expect(
      container.read(externalCalendarNotifierProvider).hasPermission,
      isFalse,
    );
    verifyNever(access.requestReadPermission());
    verifyNever(query.accounts());
    verifyNever(query.events(any, any, any, any));
  });
  test('許可操作後は端末の全アカウントを列挙し表示対象を個別選択できる', () async {
    when(access.hasReadPermission()).thenAnswer((_) async => false);
    await notifier.initialize();
    when(access.hasReadPermission()).thenAnswer((_) async => true);
    await notifier.requestAccess();
    var state = container.read(externalCalendarNotifierProvider);
    expect(state.hasPermission, isTrue);
    expect(state.connections.map((v) => v.account.id), ['first', 'second']);
    await notifier.selectCalendars('second', {'1'});
    state = container.read(externalCalendarNotifierProvider);
    expect(state.events.map((v) => v.accountId), ['first', 'second']);
    await notifier.selectCalendars('first', {});
    expect(
      container.read(externalCalendarNotifierProvider).events.single.accountId,
      'second',
    );
    expect(saved.first.calendarIds, isEmpty);
    expect(saved.last.calendarIds, {'1'});
  });
  test('許可を拒否されても連携完了にせず予定を取得しない', () async {
    when(access.requestReadPermission()).thenAnswer((_) async => false);
    await notifier.requestAccess();
    final state = container.read(externalCalendarNotifierProvider);
    expect(state.hasPermission, isFalse);
    expect(state.error, isNotEmpty);
    verifyNever(query.accounts());
  });
  test('再起動時は保存した選択を復元し表示月の前後1か月を取得する', () async {
    await notifier.setPeriod(DateTime(2026, 12));
    await notifier.initialize();
    final state = container.read(externalCalendarNotifierProvider);
    expect(state.events.single.accountId, 'first');
    verify(
      query.events('first', [calendar], DateTime(2026, 11), DateTime(2027, 2)),
    ).called(1);
    verifyNever(access.requestReadPermission());
  });
  test('端末カレンダーの変更通知で再取得して表示を更新する', () async {
    await notifier.initialize();
    clearInteractions(query);
    when(query.events(any, any, any, any)).thenAnswer((_) async => []);
    final reflected = Completer<void>();
    container.listen(externalCalendarNotifierProvider, (_, next) {
      if (next.events.isEmpty && !reflected.isCompleted) reflected.complete();
    });
    changes.add(null);
    await reflected.future;
    expect(container.read(externalCalendarNotifierProvider).events, isEmpty);
  });
  test('権限取消し後は取得済み予定も消し読み取りを継続しない', () async {
    await notifier.initialize();
    clearInteractions(query);
    when(access.hasReadPermission()).thenAnswer((_) async => false);
    await notifier.refresh();
    final state = container.read(externalCalendarNotifierProvider);
    expect(state.hasPermission, isFalse);
    expect(state.events, isEmpty);
    verifyNever(query.accounts());
    verifyNever(query.events(any, any, any, any));
  });
  test('片方の取得失敗でも他アカウントの予定を表示する', () async {
    saved = [connection, secondConnection];
    when(query.calendars('first')).thenThrow(
      const ExternalCalendarException(ExternalCalendarFailure.unavailable),
    );
    await notifier.initialize();
    final state = container.read(externalCalendarNotifierProvider);
    expect(state.events.single.accountId, 'second');
    expect(state.failures['first'], isNotNull);
  });
  test('再取得中に選択を解除しても古い結果を表示しない', () async {
    await notifier.initialize();
    final pending = Completer<List<ExternalCalendarEventDto>>();
    when(query.events(any, any, any, any)).thenAnswer((_) => pending.future);
    clearInteractions(query);
    final refreshing = notifier.refresh();
    await untilCalled(query.events(any, any, any, any));
    await notifier.selectCalendars('first', {});
    pending.complete([event('first')]);
    await refreshing;
    expect(container.read(externalCalendarNotifierProvider).events, isEmpty);
  });
  test('ユーザー切替後に古い予定と選択を反映しない', () async {
    await notifier.initialize();
    final pending = Completer<List<ExternalCalendarEventDto>>();
    when(query.events(any, any, any, any)).thenAnswer((_) => pending.future);
    clearInteractions(query);
    final refreshing = notifier.refresh();
    await untilCalled(query.events(any, any, any, any));
    container.updateOverrides([
      externalCalendarWidgetRefreshProvider.overrideWithValue(() async {
        widgetUpdates++;
      }),
      externalCalendarSupportedProvider.overrideWithValue(true),
      externalCalendarOwnerProvider.overrideWithValue('other'),
      externalCalendarUsecaseProvider.overrideWithValue(
        ExternalCalendarUsecase(access, storage, query),
      ),
    ]);
    expect(container.read(externalCalendarNotifierProvider).events, isEmpty);
    pending.complete([event('first')]);
    await refreshing;
    expect(container.read(externalCalendarNotifierProvider).events, isEmpty);
  });
  test('表示対象の変更と権限取消しをウィジェットにも反映する', () async {
    await notifier.initialize();
    final initial = widgetUpdates;
    await notifier.selectCalendars('first', {});
    expect(widgetUpdates, greaterThan(initial));
    final afterSelection = widgetUpdates;
    when(access.hasReadPermission()).thenAnswer((_) async => false);
    await notifier.refresh();
    expect(widgetUpdates, greaterThan(afterSelection));
  });

  test('オフラインでは権限・端末のカレンダーへアクセスしない', () async {
    final offline = ProviderContainer(
      overrides: [externalCalendarSupportedProvider.overrideWithValue(false)],
    );
    addTearDown(offline.dispose);
    offline.listen(externalCalendarNotifierProvider, (_, _) {});
    await offline.read(externalCalendarNotifierProvider.notifier).initialize();
    expect(
      offline.read(externalCalendarNotifierProvider).hasPermission,
      isFalse,
    );
    verifyNever(access.hasReadPermission());
    verifyNever(query.accounts());
  });
}
