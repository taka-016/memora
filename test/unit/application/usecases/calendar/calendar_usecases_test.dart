import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/application/mappers/calendar/calendar_event_mapper.dart';
import 'package:memora/application/mappers/calendar/calendar_label_mapper.dart';
import 'package:memora/application/queries/calendar/calendar_event_query_service.dart';
import 'package:memora/application/queries/calendar/calendar_label_query_service.dart';
import 'package:memora/application/usecases/calendar/create_calendar_event_usecase.dart';
import 'package:memora/application/usecases/calendar/update_calendar_event_usecase.dart';
import 'package:memora/application/usecases/calendar/delete_calendar_event_usecase.dart';
import 'package:memora/application/usecases/calendar/get_calendar_events_usecase.dart';
import 'package:memora/application/usecases/calendar/save_calendar_label_usecase.dart';
import 'package:memora/application/usecases/calendar/delete_calendar_label_usecase.dart';
import 'package:memora/application/usecases/calendar/get_calendar_labels_usecase.dart';
import 'package:memora/domain/repositories/calendar/calendar_event_repository.dart';
import 'package:memora/domain/repositories/calendar/calendar_label_repository.dart';

import 'calendar_usecases_test.mocks.dart';

@GenerateMocks([
  CalendarEventRepository,
  CalendarLabelRepository,
  CalendarEventQueryService,
  CalendarLabelQueryService,
])
void main() {
  late MockCalendarEventRepository events;
  late MockCalendarLabelRepository labels;
  late MockCalendarEventQueryService eventQuery;
  late MockCalendarLabelQueryService labelQuery;
  final dto = CalendarEventDto(
    id: '',
    groupId: 'group',
    labelId: 'label',
    title: '家族旅行',
    startDateTime: DateTime(2026, 10, 31),
    endDateTime: DateTime(2026, 11, 2),
    isAllDay: true,
  );
  const label = CalendarLabelDto(
    id: '',
    groupId: 'group',
    name: '家族全員',
    color: '#123ABC',
  );

  setUp(() {
    events = MockCalendarEventRepository();
    labels = MockCalendarLabelRepository();
    eventQuery = MockCalendarEventQueryService();
    labelQuery = MockCalendarLabelQueryService();
  });

  test('登録で予定の全内容を保存し発行されたIDを返す', () async {
    when(events.saveCalendarEvent(any)).thenAnswer((_) async => 'event');
    expect(await CreateCalendarEventUsecase(events).execute(dto), 'event');
    verify(events.saveCalendarEvent(CalendarEventMapper.toEntity(dto)))
        .called(1);
  });
  test('更新で既存IDと変更後の内容を保存する', () async {
    final changed = dto.copyWith(id: 'event', title: '運動会', labelId: 'child');
    await UpdateCalendarEventUsecase(events).execute(changed);
    verify(events.updateCalendarEvent(CalendarEventMapper.toEntity(changed)))
        .called(1);
  });
  for (final invalid in [
    dto.copyWith(title: ' '),
    dto.copyWith(endDateTime: DateTime(2026, 10, 30)),
  ]) {
    test('不正な予定は登録・更新せずApplicationの検証エラーに変換する（${invalid.title}）', () async {
      await expectLater(
        CreateCalendarEventUsecase(events).execute(invalid),
        throwsA(isA<ApplicationValidationException>()),
      );
      await expectLater(
        UpdateCalendarEventUsecase(events)
            .execute(invalid.copyWith(id: 'event')),
        throwsA(isA<ApplicationValidationException>()),
      );
      verifyZeroInteractions(events);
    });
  }
  test('更新対象のIDがない場合は登録にすり替えず拒否する', () async {
    await expectLater(
      UpdateCalendarEventUsecase(events).execute(dto),
      throwsA(isA<ApplicationValidationException>()),
    );
    verifyZeroInteractions(events);
  });
  test('ラベルの名前と色を保存し新しいIDを返す', () async {
    when(labels.saveCalendarLabel(any)).thenAnswer((_) async => 'label');
    expect(
      await SaveCalendarLabelUsecase(labels).execute(label),
      label.copyWith(id: 'label'),
    );
    verify(labels.saveCalendarLabel(CalendarLabelMapper.toEntity(label)))
        .called(1);
  });
  test('既存ラベルの名前と色の変更を同じIDで保存する', () async {
    final changed = label.copyWith(id: 'label', name: '子供', color: '#FF0000');
    when(labels.saveCalendarLabel(any)).thenAnswer((_) async => 'label');
    expect(await SaveCalendarLabelUsecase(labels).execute(changed), changed);
    verify(labels.saveCalendarLabel(CalendarLabelMapper.toEntity(changed)))
        .called(1);
  });
  test('不正なラベルは保存せずApplicationの検証エラーに変換する', () async {
    await expectLater(
      SaveCalendarLabelUsecase(labels).execute(label.copyWith(name: '')),
      throwsA(isA<ApplicationValidationException>()),
    );
    verifyZeroInteractions(labels);
  });
  test('指定グループの予定とラベルを取得する', () async {
    when(eventQuery.getCalendarEventsByGroupId('group'))
        .thenAnswer((_) async => [dto]);
    when(labelQuery.getCalendarLabelsByGroupId('group'))
        .thenAnswer((_) async => [label]);
    expect(await GetCalendarEventsUsecase(eventQuery).execute('group'), [dto]);
    expect(await GetCalendarLabelsUsecase(labelQuery).execute('group'), [
      label,
    ]);
    verify(eventQuery.getCalendarEventsByGroupId('group')).called(1);
    verify(labelQuery.getCalendarLabelsByGroupId('group')).called(1);
  });
  test('指定IDの予定とラベルを削除する', () async {
    await DeleteCalendarEventUsecase(events).execute('event');
    await DeleteCalendarLabelUsecase(labels).execute('label');
    verify(events.deleteCalendarEvent('event')).called(1);
    verify(labels.deleteCalendarLabel('label')).called(1);
  });
}
