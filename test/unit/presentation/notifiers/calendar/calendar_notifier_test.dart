import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/usecases/calendar/get_calendar_events_usecase.dart';
import 'package:memora/application/usecases/calendar/get_calendar_labels_usecase.dart';
import 'package:memora/application/usecases/calendar/create_calendar_event_usecase.dart';
import 'package:memora/application/usecases/calendar/update_calendar_event_usecase.dart';
import 'package:memora/application/usecases/calendar/delete_calendar_event_usecase.dart';
import 'package:memora/application/usecases/calendar/save_calendar_label_usecase.dart';
import 'package:memora/application/usecases/calendar/delete_calendar_label_usecase.dart';
import 'package:memora/application/usecases/calendar/reorder_calendar_labels_usecase.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/infrastructure/time/fixed_app_clock.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifier.dart';

import '../../../../helpers/test_exception.dart';
import 'calendar_notifier_test.mocks.dart';

@GenerateMocks([
  GetCalendarEventsUsecase,
  GetCalendarLabelsUsecase,
  CreateCalendarEventUsecase,
  UpdateCalendarEventUsecase,
  DeleteCalendarEventUsecase,
  SaveCalendarLabelUsecase,
  DeleteCalendarLabelUsecase,
  ReorderCalendarLabelsUsecase,
])
void main() {
  late ProviderContainer container;
  late MockGetCalendarEventsUsecase events;
  late MockGetCalendarLabelsUsecase labels;
  late MockCreateCalendarEventUsecase create;
  late MockUpdateCalendarEventUsecase update;
  late MockDeleteCalendarEventUsecase delete;
  late MockSaveCalendarLabelUsecase saveLabel;
  late MockDeleteCalendarLabelUsecase deleteLabel;
  late MockReorderCalendarLabelsUsecase reorder;
  const label = CalendarLabelDto(
    id: 'family',
    groupId: 'g1',
    name: '家族全員',
    color: '#123ABC',
  );
  final event = CalendarEventDto(
    id: 'e1',
    groupId: 'g1',
    labelId: 'family',
    title: '旅行',
    startDateTime: DateTime(2026, 9, 30, 20),
    endDateTime: DateTime(2026, 10, 2),
    isAllDay: false,
  );
  final provider = calendarNotifierProvider('g1');
  setUp(() {
    events = MockGetCalendarEventsUsecase();
    labels = MockGetCalendarLabelsUsecase();
    create = MockCreateCalendarEventUsecase();
    update = MockUpdateCalendarEventUsecase();
    delete = MockDeleteCalendarEventUsecase();
    saveLabel = MockSaveCalendarLabelUsecase();
    deleteLabel = MockDeleteCalendarLabelUsecase();
    reorder = MockReorderCalendarLabelsUsecase();
    when(events.execute(any)).thenAnswer((_) async => [event]);
    when(labels.execute(any)).thenAnswer((_) async => [label]);
    container = ProviderContainer(
      overrides: [
        appClockProvider.overrideWithValue(
          FixedAppClock(DateTime(2026, 10, 1)),
        ),
        getCalendarEventsUsecaseProvider.overrideWithValue(events),
        getCalendarLabelsUsecaseProvider.overrideWithValue(labels),
        createCalendarEventUsecaseProvider.overrideWithValue(create),
        updateCalendarEventUsecaseProvider.overrideWithValue(update),
        deleteCalendarEventUsecaseProvider.overrideWithValue(delete),
        saveCalendarLabelUsecaseProvider.overrideWithValue(saveLabel),
        deleteCalendarLabelUsecaseProvider.overrideWithValue(deleteLabel),
        reorderCalendarLabelsUsecaseProvider.overrideWithValue(reorder),
      ],
    );
    container.listen(provider, (_, _) {});
    addTearDown(container.dispose);
  });
  test('展開済みの回を単発予定として保存・削除して系列を失う操作を拒否する', () async {
    when(events.execute(any)).thenAnswer(
      (_) async => [
        event.copyWith(
          recurrenceRule: 'FREQ=DAILY;COUNT=3',
          timeZone: 'Asia/Tokyo',
        ),
      ],
    );
    final notifier = container.read(provider.notifier);
    await notifier.load();
    final occurrence = container.read(provider).events.first;
    expect(await notifier.saveEvent(occurrence), isFalse);
    expect(await notifier.deleteEvent(occurrence.id), isFalse);
    verifyNever(update.execute(any));
    verifyNever(delete.execute(any));
  });

  test('月切替で系列を表示期間だけ展開し再取得せず次の月の回を表示する', () async {
    when(events.execute(any)).thenAnswer(
      (_) async => [
        event.copyWith(
          recurrenceRule: 'FREQ=MONTHLY;COUNT=3',
          timeZone: 'Asia/Tokyo',
          startDateTime: DateTime(2026, 10, 15, 10),
          endDateTime: DateTime(2026, 10, 15, 11),
        ),
      ],
    );
    final notifier = container.read(provider.notifier);
    await notifier.load();
    expect(
      container.read(provider).eventsForDay(DateTime(2026, 10, 15)).length,
      1,
    );
    notifier.selectDate(DateTime(2026, 11, 15));
    expect(
      container.read(provider).eventsForDay(DateTime(2026, 11, 15)).length,
      1,
    );
    verify(events.execute('g1')).called(1);
  });

  test('ドラッグ順をすぐ表示し保存失敗では元へ戻して再試行できる', () async {
    final child = label.copyWith(id: 'child', name: '子供', sortOrder: 1);
    when(labels.execute('g1')).thenAnswer((_) async => [label, child]);
    final notifier = container.read(provider.notifier);
    await notifier.load();
    final pending = Completer<void>();
    when(reorder.execute('g1', any)).thenAnswer((_) => pending.future);
    final result = notifier.reorderLabels(0, 1);
    expect(container.read(provider).labels.map((label) => label.id), [
      'child',
      'family',
    ]);
    expect(container.read(provider).isSaving, isTrue);
    expect(await notifier.reorderLabels(1, 0), isFalse);
    pending.completeError(TestException('保存失敗'));
    expect(await result, isFalse);
    expect(container.read(provider).labels.map((label) => label.id), [
      'family',
      'child',
    ]);
    expect(container.read(provider).mutationError, isNotEmpty);
    when(reorder.execute('g1', any)).thenAnswer((_) async {});
    when(labels.execute('g1')).thenAnswer(
      (_) async => [child.copyWith(sortOrder: 0), label.copyWith(sortOrder: 1)],
    );
    expect(await notifier.reorderLabels(0, 1), isTrue);
    expect(container.read(provider).labels.map((label) => label.id), [
      'child',
      'family',
    ]);
    verify(reorder.execute('g1', ['child', 'family'])).called(2);
  });
  test('順序保存後の再取得失敗では保存済みの順序を保つ', () async {
    final child = label.copyWith(id: 'child', name: '子供', sortOrder: 1);
    when(labels.execute('g1')).thenAnswer((_) async => [label, child]);
    final notifier = container.read(provider.notifier);
    await notifier.load();
    when(reorder.execute('g1', any)).thenAnswer((_) async {});
    when(labels.execute('g1')).thenThrow(TestException('取得失敗'));
    expect(await notifier.reorderLabels(0, 1), isTrue);
    expect(container.read(provider).labels.map((label) => label.id), [
      'child',
      'family',
    ]);
    expect(container.read(provider).loadError, isNotEmpty);
    expect(container.read(provider).mutationError, isEmpty);
  });
  test('月境界にまたがる時刻付き予定は重なる日に表示し終了時刻の翌日は表示しない', () async {
    await container.read(provider.notifier).load();
    expect(container.read(provider).eventsForDay(DateTime(2026, 10, 1)), [
      event,
    ]);
    expect(
      container.read(provider).eventsForDay(DateTime(2026, 10, 2)),
      isEmpty,
    );
  });
  test('終日は日付で扱い終了日を含めて複数日を表示する', () async {
    final allDay = event.copyWith(
      isAllDay: true,
      startDateTime: DateTime.utc(2026, 9, 30),
      endDateTime: DateTime.utc(2026, 10, 2),
    );
    when(events.execute('g1')).thenAnswer((_) async => [allDay]);
    await container.read(provider.notifier).load();
    expect(container.read(provider).eventsForDay(DateTime(2026, 10, 2)), [
      allDay,
    ]);
    expect(
      container.read(provider).eventsForDay(DateTime(2026, 10, 3)),
      isEmpty,
    );
  });
  test('日付を選択すると月も切り替わり別グループは独立する', () {
    container.read(provider.notifier).selectDate(DateTime(2026, 11, 5));
    expect(container.read(provider).selectedDate, DateTime(2026, 11, 5));
    expect(container.read(provider).month, DateTime(2026, 11));
    expect(container.read(calendarNotifierProvider('g2')).events, isEmpty);
  });
  test('取得失敗を空表示と区別し再試行で復旧する', () async {
    when(events.execute('g1')).thenThrow(TestException('取得失敗'));
    await container.read(provider.notifier).load();
    expect(container.read(provider).loadError, isNotEmpty);
    when(events.execute('g1')).thenAnswer((_) async => [event]);
    await container.read(provider.notifier).load();
    expect(container.read(provider).loadError, isEmpty);
    expect(container.read(provider).events, [event]);
  });
  test('後から完了した古い取得結果は再試行の結果を上書きしない', () async {
    final pending = Completer<List<CalendarEventDto>>();
    when(events.execute('g1')).thenAnswer((_) => pending.future);
    final first = container.read(provider.notifier).load();
    when(events.execute('g1')).thenAnswer((_) async => []);
    await container.read(provider.notifier).load();
    pending.complete([event]);
    await first;
    expect(container.read(provider).events, isEmpty);
  });
  test('共通ラベルで代理登録しラベル変更と削除後も再取得する', () async {
    await container.read(provider.notifier).load();
    when(create.execute(any)).thenAnswer((_) async => 'new');
    expect(
      await container.read(provider.notifier).saveEvent(event.copyWith(id: '')),
      isTrue,
    );
    verify(create.execute(event.copyWith(id: ''))).called(1);
    expect(
      await container
          .read(provider.notifier)
          .saveEvent(event.copyWith(title: '変更')),
      isTrue,
    );
    verify(update.execute(event.copyWith(title: '変更'))).called(1);
    when(events.execute('g1')).thenAnswer((_) async => []);
    expect(await container.read(provider.notifier).deleteEvent('e1'), isTrue);
    expect(container.read(provider).events, isEmpty);
  });
  test('別グループの予定とラベル指定を保存前に拒否する', () async {
    await container.read(provider.notifier).load();
    expect(
      await container
          .read(provider.notifier)
          .saveEvent(event.copyWith(labelId: 'other')),
      isFalse,
    );
    expect(
      await container
          .read(provider.notifier)
          .saveEvent(event.copyWith(groupId: 'g2')),
      isFalse,
    );
    expect(
      await container
          .read(provider.notifier)
          .saveLabel(label.copyWith(groupId: 'g2')),
      isFalse,
    );
    verifyZeroInteractions(create);
    verifyZeroInteractions(update);
    verifyZeroInteractions(saveLabel);
  });
  test('保存失敗時は既存表示を保ち再試行できる', () async {
    await container.read(provider.notifier).load();
    when(update.execute(any)).thenThrow(TestException('保存失敗'));
    expect(await container.read(provider.notifier).saveEvent(event), isFalse);
    expect(container.read(provider).events, [event]);
    expect(container.read(provider).mutationError, isNotEmpty);
    when(update.execute(any)).thenAnswer((_) async {});
    expect(await container.read(provider.notifier).saveEvent(event), isTrue);
  });
  test('保存済みで再取得だけ失敗した場合は重複登録を促さず再取得を案内する', () async {
    await container.read(provider.notifier).load();
    when(create.execute(any)).thenAnswer((_) async => 'new');
    when(events.execute('g1')).thenThrow(TestException('再取得失敗'));
    expect(
      await container.read(provider.notifier).saveEvent(event.copyWith(id: '')),
      isTrue,
    );
    expect(container.read(provider).loadError, isNotEmpty);
    expect(container.read(provider).mutationError, isEmpty);
  });
  test('保存中の重複操作を拒否しラベル変更後の表示を更新する', () async {
    await container.read(provider.notifier).load();
    final pending = Completer<CalendarLabelDto>();
    when(saveLabel.execute(any)).thenAnswer((_) => pending.future);
    final first = container
        .read(provider.notifier)
        .saveLabel(label.copyWith(name: '太郎'));
    expect(await container.read(provider.notifier).saveEvent(event), isFalse);
    final changed = label.copyWith(name: '太郎');
    when(labels.execute('g1')).thenAnswer((_) async => [changed]);
    pending.complete(changed);
    expect(await first, isTrue);
    expect(container.read(provider).labels, [changed]);
  });
}
