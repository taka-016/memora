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
  const second = ExternalCalendarAccount(
    id: 'second',
    email: 'second@example.com',
  );
  const calendar = ExternalCalendarDto(id: 'calendar', name: '個人');
  final connection = ExternalCalendarConnection(
    account: account,
    calendarIds: {'calendar'},
  );
  final secondConnection = ExternalCalendarConnection(
    account: second,
    calendarIds: {'calendar'},
  );
  ExternalCalendarEventDto event(String accountId) => ExternalCalendarEventDto(
    accountId: accountId,
    id: 'e',
    calendarId: 'calendar',
    calendarName: '個人',
    title: '$accountIdの予定',
    startDateTime: DateTime(2026, 11, 1),
    endDateTime: DateTime(2026, 11, 1, 1),
    isAllDay: false,
  );
  late MockExternalCalendarQueryService query;
  late MockExternalCalendarAuthService auth;
  late MockExternalCalendarSettingsStorage storage;
  late ProviderContainer container;
  late ExternalCalendarNotifier notifier;
  late List<ExternalCalendarConnection> saved;

  setUp(() {
    query = MockExternalCalendarQueryService();
    auth = MockExternalCalendarAuthService();
    storage = MockExternalCalendarSettingsStorage();
    saved = [connection];
    when(storage.load('owner')).thenAnswer((_) async => saved);
    when(storage.save('owner', any)).thenAnswer((call) async {
      saved = List<ExternalCalendarConnection>.from(
        call.positionalArguments[1] as List,
      );
    });
    when(storage.remove('owner')).thenAnswer((_) async {
      saved = [];
    });
    when(auth.connect()).thenAnswer((_) async => account);
    when(query.calendars(any)).thenAnswer((_) async => [calendar]);
    when(query.events(any, any, any, any)).thenAnswer(
      (call) async => [event(call.positionalArguments.first as String)],
    );
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

  test('保存設定を復元し表示月の前後1か月を取得して選択変更を保存する', () async {
    await notifier.setPeriod(DateTime(2026, 12));
    await notifier.initialize();
    final state = container.read(externalCalendarNotifierProvider);
    expect(state.connections.single.calendarIds, {'calendar'});
    expect(state.events.single.title, 'googleの予定');
    verify(auth.restoreAccounts([account])).called(1);
    verify(
      query.events('google', [calendar], DateTime(2026, 11), DateTime(2027, 2)),
    ).called(1);
    await notifier.selectCalendars('google', {});
    expect(container.read(externalCalendarNotifierProvider).events, isEmpty);
    expect(saved.single.calendarIds, isEmpty);
  });

  test('別アカウントを追加しても既存の選択を維持し両方の予定を取得する', () async {
    await notifier.initialize();
    when(auth.connect()).thenAnswer((_) async => second);
    await notifier.connect();
    var state = container.read(externalCalendarNotifierProvider);
    expect(state.connections.map((v) => v.account.id), ['google', 'second']);
    expect(state.connections.first.calendarIds, {'calendar'});
    expect(state.connections.last.calendarIds, isEmpty);
    expect(state.events.single.accountId, 'google');
    await notifier.selectCalendars('second', {'calendar'});
    state = container.read(externalCalendarNotifierProvider);
    expect(state.events.map((v) => v.accountId), ['google', 'second']);
    expect(saved.map((v) => v.calendarIds), [
      {'calendar'},
      {'calendar'},
    ]);
  });

  test('1アカウントの認証失敗でも他アカウントの取得結果を反映する', () async {
    saved = [connection, secondConnection];
    when(query.calendars('google')).thenThrow(
      const ExternalCalendarException(ExternalCalendarFailure.authentication),
    );
    await notifier.initialize();
    final state = container.read(externalCalendarNotifierProvider);
    expect(state.events.single.accountId, 'second');
    expect(
      state.failures['google']!.kind,
      ExternalCalendarFailure.authentication,
    );
    expect(state.failures.containsKey('second'), isFalse);
  });

  test('取得失敗では前回予定を保持し再取得の成功で削除を反映する', () async {
    await notifier.initialize();
    when(query.events(any, any, any, any)).thenThrow(
      const ExternalCalendarException(ExternalCalendarFailure.network),
    );
    await notifier.refresh();
    expect(
      container.read(externalCalendarNotifierProvider).events.single.accountId,
      'google',
    );
    expect(
      container.read(externalCalendarNotifierProvider).failures['google'],
      isNotNull,
    );
    when(query.events(any, any, any, any)).thenAnswer((_) async => []);
    await notifier.refresh();
    expect(container.read(externalCalendarNotifierProvider).events, isEmpty);
    expect(container.read(externalCalendarNotifierProvider).failures, isEmpty);
  });

  test('連携のキャンセルは既存アカウントの予定と設定を維持する', () async {
    await notifier.initialize();
    when(auth.connect()).thenThrow(
      const ExternalCalendarException(ExternalCalendarFailure.canceled),
    );
    await notifier.connect();
    final state = container.read(externalCalendarNotifierProvider);
    expect(state.connections.single.account.id, 'google');
    expect(state.events.single.accountId, 'google');
    verifyNever(storage.save(any, any));
  });

  test('同じアカウントの再認証は重複を作らず他アカウントの選択も維持する', () async {
    saved = [connection, secondConnection];
    await notifier.initialize();
    await notifier.connect();
    final state = container.read(externalCalendarNotifierProvider);
    expect(state.connections.map((v) => v.account.id), ['google', 'second']);
    expect(state.connections.map((v) => v.calendarIds), [
      {'calendar'},
      {'calendar'},
    ]);
  });

  test('一方の解除は他アカウントを維持し処理中の古い結果も反映しない', () async {
    saved = [connection, secondConnection];
    await notifier.initialize();
    final pending = Completer<List<ExternalCalendarEventDto>>();
    when(query.events('google', any, any, any))
        .thenAnswer((_) => pending.future);
    clearInteractions(query);
    final loading = notifier.refresh();
    await untilCalled(query.events('google', any, any, any));
    await notifier.disconnect('google');
    pending.complete([event('google')]);
    await loading;
    final state = container.read(externalCalendarNotifierProvider);
    expect(state.connections.single.account.id, 'second');
    expect(state.events.single.accountId, 'second');
    expect(saved.single.account.id, 'second');
    verify(auth.disconnect('google')).called(1);
    verifyNever(auth.disconnect('second'));
  });

  test('最後のアカウント解除は保存設定も削除する', () async {
    await notifier.initialize();
    await notifier.disconnect('google');
    expect(
      container.read(externalCalendarNotifierProvider).connections,
      isEmpty,
    );
    expect(container.read(externalCalendarNotifierProvider).events, isEmpty);
    verify(storage.remove('owner')).called(1);
  });

  test('ユーザー切替で前の予定・選択・処理中の結果が混入しない', () async {
    await notifier.initialize();
    final pending = Completer<List<ExternalCalendarEventDto>>();
    when(query.events(any, any, any, any)).thenAnswer((_) => pending.future);
    clearInteractions(query);
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
    pending.complete([event('google')]);
    await loading;
    expect(container.read(externalCalendarNotifierProvider).events, isEmpty);
    await container
        .read(externalCalendarNotifierProvider.notifier)
        .initialize();
    expect(
      container.read(externalCalendarNotifierProvider).connections,
      isEmpty,
    );
  });

  for (final operation in ['connect', 'select', 'disconnect']) {
    test('月移動が$operationの完了を捨てず移動後の期間を使用する', () async {
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
        when(auth.disconnect(any)).thenAnswer((_) async {
          started.complete();
          await pending.future;
        });
      }
      final working = switch (operation) {
        'connect' => notifier.connect(),
        'select' => notifier.selectCalendars('google', {'calendar'}),
        _ => notifier.disconnect('google'),
      };
      await started.future;
      await notifier.setPeriod(DateTime(2027, 2));
      pending.complete();
      await working;
      final state = container.read(externalCalendarNotifierProvider);
      expect(state.isBusy, isFalse);
      expect(state.month, DateTime(2027, 2));
      expect(
        state.connections,
        operation == 'disconnect' ? isEmpty : isNotEmpty,
      );
    });
  }

  test('初期復元中の月移動は復元を捨てず移動後の期間を取得する', () async {
    final pending = Completer<List<ExternalCalendarConnection>>();
    when(storage.load('owner')).thenAnswer((_) => pending.future);
    final initialization = notifier.initialize();
    await notifier.setPeriod(DateTime(2027, 2));
    pending.complete([connection]);
    await initialization;
    expect(
      container.read(externalCalendarNotifierProvider).connections,
      isNotEmpty,
    );
    verify(
      query.events('google', [calendar], DateTime(2027, 1), DateTime(2027, 4)),
    ).called(1);
  });

  test('オフラインでは設定・SDK・APIに触れない', () async {
    final offline = ProviderContainer(
      overrides: [externalCalendarSupportedProvider.overrideWithValue(false)],
    );
    addTearDown(offline.dispose);
    offline.listen(externalCalendarNotifierProvider, (_, _) {});
    await offline.read(externalCalendarNotifierProvider.notifier).initialize();
    expect(offline.read(externalCalendarNotifierProvider).connections, isEmpty);
  });
}
