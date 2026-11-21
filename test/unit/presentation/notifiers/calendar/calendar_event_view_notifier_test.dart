import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_event_view_notifier.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import '../../../application/usecases/calendar/calendar_usecases_test.mocks.dart';

void main() {
  final original = CalendarEventDto(
    id: 'event',
    groupId: 'family',
    labelType: 'group',
    title: '予定',
    startDateTime: DateTime.utc(2026, 10, 1),
    endDateTime: DateTime.utc(2026, 10, 2),
    isAllDay: true,
    version: 1,
  );
  late MockCalendarEventQueryService query;
  late ProviderContainer container;
  late CalendarEventViewNotifierProvider provider;
  late CalendarEventViewNotifier notifier;

  setUp(() {
    query = MockCalendarEventQueryService();
    container = ProviderContainer(
      overrides: [
        getCalendarEventByIdProvider.overrideWithValue(
          query.getCalendarEventById,
        ),
      ],
    );
    addTearDown(container.dispose);
    provider = calendarEventViewNotifierProvider(Object(), original);
    container.listen(provider, (_, _) {});
    notifier = container.read(provider.notifier);
  });

  test('取得失敗後は保存済みの予定を再取得し一致した色ラベルを照会に使う', () async {
    const label = CalendarLabelDto(
      id: 'trip-label',
      groupId: 'friends',
      name: '旅行',
      color: '#123ABC',
    );
    final saved = original.copyWith(
      groupId: label.groupId,
      labelId: label.id,
      labelType: 'custom',
      version: 2,
    );
    expect(container.read(provider).event, original);
    verifyZeroInteractions(query);
    final lookup = Completer<CalendarEventDto?>();
    when(query.getCalendarEventById(saved.id)).thenAnswer((_) => lookup.future);
    final refresh = notifier.refreshAfterSave(
      id: saved.id,
      start: saved.startDateTime,
      label: label,
    );
    expect(container.read(provider).isLoading, isTrue);
    expect(container.read(provider).event, isNull);
    lookup.completeError(TestException('予定の取得失敗'));
    await refresh;

    expect(container.read(provider).hasError, isTrue);
    when(query.getCalendarEventById(saved.id)).thenAnswer((_) async => saved);
    await notifier.retry();

    final state = container.read(provider);
    expect(state.event, saved);
    expect(state.savedLabelName, label.name);
    expect(state.hasError, isFalse);
    verify(query.getCalendarEventById(saved.id)).called(2);
  });

  test('再編集へ同じ取得結果から選択した回と系列を渡せる', () async {
    final series = original.copyWith(
      id: 'new-series',
      recurrenceRule: 'FREQ=DAILY;COUNT=3',
      version: 2,
    );
    final selected = DateTime.utc(2026, 10, 3);
    when(query.getCalendarEventById(series.id)).thenAnswer((_) async => series);

    await notifier.refreshAfterSave(id: series.id, start: selected);

    final state = container.read(provider);
    expect(state.series, same(series));
    expect(state.event?.id, series.id);
    expect(state.event?.originalStartDateTime, selected);
    expect(state.event?.version, series.version);
  });

  test('前の取得が遅れて失敗しても最新の保存結果を照会に表示する', () async {
    final delayed = Completer<CalendarEventDto?>();
    when(query.getCalendarEventById(original.id))
        .thenAnswer((_) => delayed.future);
    final first = notifier.refreshAfterSave(
      id: original.id,
      start: original.startDateTime,
    );
    final latest = original.copyWith(title: '変更後の予定', version: 3);
    when(query.getCalendarEventById(latest.id)).thenAnswer((_) async => latest);
    await notifier.refreshAfterSave(id: latest.id, start: latest.startDateTime);
    delayed.completeError(TestException('前の取得失敗'));
    await first;

    final state = container.read(provider);
    expect(state.event, latest);
    expect(state.hasError, isFalse);
  });
}
