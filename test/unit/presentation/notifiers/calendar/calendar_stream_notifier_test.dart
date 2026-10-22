import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/usecases/calendar/watch_calendar_events_usecase.dart';
import 'package:memora/application/usecases/calendar/watch_calendar_labels_usecase.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/infrastructure/time/fixed_app_clock.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifier.dart';

import '../../../../helpers/test_exception.dart';
import 'calendar_notifier_test.mocks.dart';
import 'calendar_stream_test_support.dart';

void main() {
  final event = CalendarEventDto(
    id: 'e',
    groupId: 'g',
    labelId: 'l',
    title: '予定',
    startDateTime: DateTime(2026, 10, 2),
    endDateTime: DateTime(2026, 10, 2),
    isAllDay: true,
    version: 1,
  );
  const label = CalendarLabelDto(
    id: 'l',
    groupId: 'g',
    name: '家族',
    color: '#123ABC',
    version: 1,
  );
  late EventSource events;
  late LabelSource labels;
  late ProviderContainer container;
  late MockCreateCalendarEventUsecase create;
  late MockUpdateCalendarEventUsecase update;
  late MockReorderCalendarLabelsUsecase reorder;
  late MockGetCalendarEventsUsecase getEvents;
  final provider = calendarNotifierProvider('g');
  Future<void> flush() => Future<void>(() {});
  setUp(() {
    events = EventSource();
    labels = LabelSource();
    create = MockCreateCalendarEventUsecase();
    update = MockUpdateCalendarEventUsecase();
    reorder = MockReorderCalendarLabelsUsecase();
    getEvents = MockGetCalendarEventsUsecase();
    container = ProviderContainer(
      overrides: [
        appClockProvider.overrideWithValue(
          FixedAppClock(DateTime(2026, 10, 1)),
        ),
        watchCalendarEventsUsecaseProvider.overrideWithValue(
          WatchCalendarEventsUsecase(events),
        ),
        watchCalendarLabelsUsecaseProvider.overrideWithValue(
          WatchCalendarLabelsUsecase(labels),
        ),
        createCalendarEventUsecaseProvider.overrideWithValue(create),
        updateCalendarEventUsecaseProvider.overrideWithValue(update),
        reorderCalendarLabelsUsecaseProvider.overrideWithValue(reorder),
        getCalendarEventsUsecaseProvider.overrideWithValue(getEvents),
      ],
    );
    container.listen(provider, (_, _) {});
    addTearDown(() async {
      container.dispose();
      for (final stream in events.streams) {
        await stream.close();
      }
      for (final stream in labels.streams) {
        await stream.close();
      }
    });
  });
  Future<void> start() async {
    await container.read(provider.notifier).load();
    events.streams.last.add([event]);
    labels.streams.last.add([label]);
    await flush();
  }

  test('外部変更を受信して選択日と月を保ち通常保存と月移動では購読し直さない', () async {
    await start();
    final notifier = container.read(provider.notifier);
    notifier.selectDate(DateTime(2026, 11, 2));
    events.streams.last.add([
      event.copyWith(
        title: '外部変更',
        startDateTime: DateTime(2026, 11, 2),
        endDateTime: DateTime(2026, 11, 2),
      ),
    ]);
    await flush();
    expect(container.read(provider).events.single.title, '外部変更');
    expect(container.read(provider).selectedDate, DateTime(2026, 11, 2));
    when(create.execute(any)).thenAnswer((_) async => 'new');
    expect(await notifier.saveEvent(event.copyWith(id: '')), isTrue);
    expect(events.streams, hasLength(1));
    verifyZeroInteractions(getEvents);
  });
  test('予定とラベルの失敗を別々に保持し既存表示を残して再試行する', () async {
    await start();
    events.streams.last.addError(TestException('予定取得失敗'));
    labels.streams.last.addError(TestException('ラベル取得失敗'));
    await flush();
    expect(container.read(provider).events, [event]);
    expect(container.read(provider).labels, [label]);
    labels.streams.last.add([label.copyWith(name: '更新')]);
    await flush();
    expect(container.read(provider).eventLoadError, isNotEmpty);
    expect(container.read(provider).labelLoadError, isEmpty);
    await container.read(provider.notifier).load();
    expect(events.cancelled, 1);
    expect(labels.cancelled, 1);
    events.streams.first.add([event.copyWith(title: '古い結果')]);
    events.streams.last.add([]);
    labels.streams.last.add([label]);
    await flush();
    expect(container.read(provider).events, isEmpty);
    expect(container.read(provider).loadError, isEmpty);
    expect(container.read(provider).isLoading, isFalse);
  });
  test('初回の一方の失敗と他方の成功で空の取得成功として扱わない', () async {
    await container.read(provider.notifier).load();
    events.streams.last.addError(TestException('初回失敗'));
    labels.streams.last.add([label]);
    await flush();
    expect(container.read(provider).hasLoadedEvents, isFalse);
    expect(container.read(provider).hasLoadedLabels, isTrue);
    expect(container.read(provider).isLoading, isFalse);
    expect(container.read(provider).loadError, isNotEmpty);
  });
  test('保存後に監視が失敗しても保存成功を維持し期待バージョンを差し替えない', () async {
    await start();
    events.streams.last.add([event.copyWith(version: 2)]);
    await flush();
    when(update.execute(any)).thenAnswer((_) async {
      events.streams.last.addError(TestException('受信失敗'));
    });
    final input = event.copyWith(title: '入力');
    expect(await container.read(provider.notifier).saveEvent(input), isTrue);
    await flush();
    verify(update.execute(input)).called(1);
    expect(container.read(provider).mutationError, isEmpty);
    expect(container.read(provider).eventLoadError, isNotEmpty);
  });
  test('ラベル並べ替え中の外部通知を保存失敗時に古い一覧で上書きしない', () async {
    await start();
    final second = label.copyWith(id: 'l2', name: '子供', sortOrder: 1);
    labels.streams.last.add([label, second]);
    await flush();
    final pending = Completer<void>();
    when(
      reorder.execute(any, any, expectedVersions: anyNamed('expectedVersions')),
    ).thenAnswer((_) => pending.future);
    final result = container.read(provider.notifier).reorderLabels(0, 1);
    expect(container.read(provider).labels.first.id, 'l2');
    labels.streams.last.add([label.copyWith(name: '他者の更新'), second]);
    await flush();
    pending.completeError(TestException('競合'));
    expect(await result, isFalse);
    expect(container.read(provider).labels.first.name, '他者の更新');
    verify(
      reorder.execute('g', ['l2', 'l'], expectedVersions: {'l': 1, 'l2': 1}),
    ).called(1);
  });
  test('グループごとに購読を共有し破棄で旧購読を解除する', () async {
    await start();
    final shared = container.listen(provider, (_, _) {});
    expect(events.streams, hasLength(1));
    shared.close();
    final other = calendarNotifierProvider('other');
    final subscription = container.listen(other, (_, _) {});
    await container.read(other.notifier).load();
    expect(events.groups, ['g', 'other']);
    subscription.close();
    await container.pump();
    expect(events.cancelled, 1);
    container.invalidate(provider);
    await container.pump();
    expect(events.cancelled, 2);
  });
}
