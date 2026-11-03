import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/application/exceptions/external_calendar_exception.dart';
import 'package:memora/application/queries/calendar/external_calendar_query_service.dart';
import 'package:memora/application/services/calendar/external_calendar_auth_service.dart';
import 'package:memora/application/services/calendar/external_calendar_settings_storage.dart';
import 'package:memora/application/usecases/calendar/external_calendar_usecase.dart';
import 'package:memora/composition_root/providers/external_calendar_providers.dart';
import 'package:memora/presentation/notifiers/calendar/external_calendar_notifier.dart';

@GenerateNiceMocks([
  MockSpec<ExternalCalendarQueryService>(),
  MockSpec<ExternalCalendarAuthService>(),
  MockSpec<ExternalCalendarSettingsStorage>(),
])
import 'external_calendar_notifier_test.mocks.dart';

void main() {
  const account = ExternalCalendarAccount(
    id: 'google',
    email: 'me@example.com',
  );
  const calendar = ExternalCalendarDto(id: 'calendar', name: '個人');
  final connection = ExternalCalendarConnection(
    account: account,
    calendarIds: {'calendar'},
  );
  final event = ExternalCalendarEventDto(
    id: 'e',
    calendarId: 'calendar',
    calendarName: '個人',
    title: '個人の予定',
    startDateTime: DateTime(2026, 11, 1),
    endDateTime: DateTime(2026, 11, 1, 1),
    isAllDay: false,
  );
  late MockExternalCalendarQueryService query;
  late MockExternalCalendarAuthService auth;
  late MockExternalCalendarSettingsStorage storage;
  late ProviderContainer container;
  late ExternalCalendarNotifier notifier;

  setUp(() {
    query = MockExternalCalendarQueryService();
    auth = MockExternalCalendarAuthService();
    storage = MockExternalCalendarSettingsStorage();
    when(storage.load('owner')).thenAnswer((_) async => connection);
    when(auth.connect()).thenAnswer((_) async => account);
    when(query.calendars('google')).thenAnswer((_) async => [calendar]);
    when(query.events(any, any, any, any)).thenAnswer((_) async => [event]);
    container = ProviderContainer(
      overrides: [
        externalCalendarSupportedProvider.overrideWithValue(true),
        externalCalendarOwnerProvider.overrideWithValue('owner'),
        externalCalendarUsecaseProvider.overrideWithValue(
          ExternalCalendarUsecase(auth, storage, query),
        ),
      ],
    );
    container.listen(externalCalendarNotifierProvider, (_, _) {});
    notifier = container.read(externalCalendarNotifierProvider.notifier);
    addTearDown(container.dispose);
  });

  test('保存設定を復元して選択した予定を取得し期間変更で取得し直す', () async {
    await notifier.initialize();
    await notifier.setPeriod(DateTime(2026, 11));
    var state = container.read(externalCalendarNotifierProvider);
    expect(state.connection!.calendarIds, {'calendar'});
    expect(state.events.single.title, '個人の予定');
    verify(
      query.events('google', [calendar], DateTime(2026, 10), DateTime(2027, 1)),
    ).called(1);
    await notifier.selectCalendars({});
    state = container.read(externalCalendarNotifierProvider);
    expect(state.events, isEmpty);
    verify(
      storage.save(
        'owner',
        argThat(
          isA<ExternalCalendarConnection>().having(
            (v) => v.calendarIds,
            '選択',
            isEmpty,
          ),
        ),
      ),
    ).called(1);
  });
  test('取得失敗は前回表示と最新でないことを保持し再試行で削除を反映する', () async {
    await notifier.initialize();
    when(query.events(any, any, any, any)).thenThrow(
      const ExternalCalendarException(ExternalCalendarFailure.network),
    );
    await notifier.refresh();
    var state = container.read(externalCalendarNotifierProvider);
    expect(state.events, [event]);
    expect(state.isStale, isTrue);
    expect(state.error, isNotEmpty);
    expect(state.needsAuthentication, isFalse);
    when(query.events(any, any, any, any)).thenAnswer((_) async => []);
    await notifier.refresh();
    state = container.read(externalCalendarNotifierProvider);
    expect(state.events, isEmpty);
    expect(state.isStale, isFalse);
  });
  test('保存IDがあっても認証失敗なら再認証を案内し連携完了にしない', () async {
    when(query.calendars(any)).thenThrow(
      const ExternalCalendarException(ExternalCalendarFailure.authentication),
    );
    await notifier.initialize();
    final state = container.read(externalCalendarNotifierProvider);
    expect(state.needsAuthentication, isTrue);
    expect(state.events, isEmpty);
    verifyNever(query.events(any, any, any, any));
  });
  test('連携操作のキャンセルは新しい連携として保存しない', () async {
    when(storage.load('owner')).thenAnswer((_) async => null);
    await notifier.initialize();
    when(auth.connect()).thenThrow(
      const ExternalCalendarException(ExternalCalendarFailure.canceled),
    );
    await notifier.connect();
    expect(container.read(externalCalendarNotifierProvider).connection, isNull);
    verifyNever(storage.save(any, any));
  });
  test('解除直後に表示を消し処理中の古い取得結果を反映しない', () async {
    await notifier.initialize();
    final pending = Completer<List<ExternalCalendarEventDto>>();
    when(query.events(any, any, any, any)).thenAnswer((_) => pending.future);
    final loading = notifier.refresh();
    await untilCalled(query.events(any, any, any, any));
    await notifier.disconnect();
    pending.complete([event]);
    await loading;
    expect(container.read(externalCalendarNotifierProvider).connection, isNull);
    expect(container.read(externalCalendarNotifierProvider).events, isEmpty);
    verify(storage.remove('owner')).called(1);
    verify(auth.disconnect()).called(1);
  });
  test('ユーザー切替で前の予定・選択と処理中の結果が混入しない', () async {
    await notifier.initialize();
    final pending = Completer<List<ExternalCalendarEventDto>>();
    when(query.events(any, any, any, any)).thenAnswer((_) => pending.future);
    final loading = notifier.refresh();
    await untilCalled(query.events(any, any, any, any));
    container.updateOverrides([
      externalCalendarSupportedProvider.overrideWithValue(true),
      externalCalendarOwnerProvider.overrideWithValue('other'),
      externalCalendarUsecaseProvider.overrideWithValue(
        ExternalCalendarUsecase(auth, storage, query),
      ),
    ]);
    expect(container.read(externalCalendarNotifierProvider).events, isEmpty);
    pending.complete([event]);
    await loading;
    expect(container.read(externalCalendarNotifierProvider).events, isEmpty);
    await container
        .read(externalCalendarNotifierProvider.notifier)
        .initialize();
    expect(container.read(externalCalendarNotifierProvider).connection, isNull);
  });
  for (final operation in ['connect', 'select', 'disconnect']) {
    test('月移動が$operationの完了を捨てず操作を再開できる', () async {
      await notifier.initialize();
      final pending = Completer<void>();
      final started = Completer<void>();
      if (operation == 'connect') {
        when(auth.connect()).thenAnswer((_) async {
          started.complete();
          await pending.future;
          return account;
        });
      } else if (operation == 'select') {
        when(storage.save(any, any)).thenAnswer((_) async {
          started.complete();
          await pending.future;
        });
      } else {
        when(auth.disconnect()).thenAnswer((_) async {
          started.complete();
          await pending.future;
        });
      }
      final working = switch (operation) {
        'connect' => notifier.connect(),
        'select' => notifier.selectCalendars({'calendar'}),
        _ => notifier.disconnect(),
      };
      await started.future;
      await notifier.setPeriod(DateTime(2027, 2));
      pending.complete();
      await working;
      final state = container.read(externalCalendarNotifierProvider);
      expect(state.isBusy, isFalse);
      expect(state.month, DateTime(2027, 2));
      if (operation == 'disconnect') {
        expect(state.connection, isNull);
      } else {
        expect(state.connection!.account.id, 'google');
      }
    });
  }
  test('初期復元中の月移動は復元を捨てず移動後の期間を取得する', () async {
    final pending = Completer<ExternalCalendarConnection?>();
    when(storage.load('owner')).thenAnswer((_) => pending.future);
    final initialization = notifier.initialize();
    await notifier.setPeriod(DateTime(2027, 2));
    pending.complete(connection);
    await initialization;
    expect(
      container.read(externalCalendarNotifierProvider).connection,
      isNotNull,
    );
    verify(
      query.events('google', [calendar], DateTime(2027, 1), DateTime(2027, 4)),
    ).called(1);
  });
  test('同じGoogleアカウントの再認証では表示対象を維持する', () async {
    await notifier.initialize();
    await notifier.connect();
    expect(
      container.read(externalCalendarNotifierProvider).connection!.calendarIds,
      {'calendar'},
    );
    expect(container.read(externalCalendarNotifierProvider).events, [event]);
  });
  test('別Googleアカウントへの切替では前の表示対象を引き継がない', () async {
    await notifier.initialize();
    when(auth.connect()).thenAnswer(
      (_) async => const ExternalCalendarAccount(
        id: 'second',
        email: 'second@example.com',
      ),
    );
    await notifier.connect();
    final state = container.read(externalCalendarNotifierProvider);
    expect(state.connection!.account.id, 'second');
    expect(state.connection!.calendarIds, isEmpty);
    expect(state.events, isEmpty);
  });
  test('オフラインでは設定・SDK・APIに触れない', () async {
    final offline = ProviderContainer(
      overrides: [externalCalendarSupportedProvider.overrideWithValue(false)],
    );
    addTearDown(offline.dispose);
    offline.listen(externalCalendarNotifierProvider, (_, _) {});
    await offline.read(externalCalendarNotifierProvider.notifier).initialize();
    expect(offline.read(externalCalendarNotifierProvider).connection, isNull);
  });
}
