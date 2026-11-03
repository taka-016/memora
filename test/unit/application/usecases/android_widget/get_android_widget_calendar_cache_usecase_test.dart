import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/queries/calendar/calendar_event_query_service.dart';
import 'package:memora/application/queries/calendar/calendar_label_query_service.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_expander.dart';
import 'package:memora/application/usecases/android_widget/get_android_widget_calendar_cache_usecase.dart';
import 'package:memora/infrastructure/services/iana_calendar_time_zone.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_android_widget_calendar_cache_usecase_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<CalendarEventQueryService>(),
  MockSpec<CalendarLabelQueryService>(),
  MockSpec<GroupQueryService>(),
])
void main() {
  late MockCalendarEventQueryService events;
  late MockCalendarLabelQueryService labels;
  late MockGroupQueryService groups;
  late GetAndroidWidgetCalendarCacheUsecase usecase;

  setUp(() {
    events = MockCalendarEventQueryService();
    labels = MockCalendarLabelQueryService();
    groups = MockGroupQueryService();
    when(groups.getGroupWithMembersById('group')).thenAnswer(
      (_) async => const GroupDto(
        id: 'group',
        ownerId: 'owner',
        name: '家族',
        members: [],
      ),
    );
    usecase = GetAndroidWidgetCalendarCacheUsecase(
      events: events,
      labels: labels,
      groups: groups,
      expander: CalendarRecurrenceExpander(IanaCalendarTimeZone()),
      mode: AppMode.offline,
    );
  });

  CalendarEventDto event(
    String id,
    DateTime start,
    DateTime end, {
    bool allDay = true,
    String? rule,
  }) => CalendarEventDto(
    id: id,
    groupId: 'group',
    labelType: 'group',
    title: id,
    startDateTime: start,
    endDateTime: end,
    isAllDay: allDay,
    recurrenceRule: rule,
  );

  test('月の前後を含む週を作り、予定名と配色を全件保持する', () async {
    when(events.getCalendarEventsByGroupId('group')).thenAnswer(
      (_) async => [
        for (var i = 0; i < 4; i++)
          event('予定$i', DateTime(2026, 11, 1), DateTime(2026, 11, 1)),
        event('月またぎ', DateTime(2026, 11, 30), DateTime(2026, 12, 2)),
      ],
    );
    final cache = (await usecase.execute('group', DateTime(2026, 11)))!;
    expect(cache['sourceMode'], 'offline');
    expect(cache['groupId'], 'group');
    final days = cache['days'] as List;
    expect(days, hasLength(35));
    expect(days.first['date'], '2026-11-01');
    expect(days.last['date'], '2026-12-05');
    final items = days.first['events'] as List;
    expect(items.map((e) => e['title']), ['予定0', '予定1', '予定2', '予定3']);
    expect(items.first['color'], '#4CAF50');
    expect(items.first['timeLabel'], '終日');
    expect(items.first['isAllDay'], isTrue);
    expect(cache['months'], isA<Map>());
    expect((cache['months'] as Map).keys, [
      '2026-09-01',
      '2026-10-01',
      '2026-11-01',
      '2026-12-01',
      '2027-01-01',
    ]);
    verify(events.getCalendarEventsByGroupId('group')).called(1);
    verify(labels.getCalendarLabelsByGroupId('group')).called(1);
    expect(days[30]['events'].single['title'], '月またぎ');
  });

  test('繰り返しを展開し、午前0時終了の予定を翌日に表示しない', () async {
    when(events.getCalendarEventsByGroupId('group')).thenAnswer(
      (_) async => [
        event(
          '毎週',
          DateTime(2026, 10, 26),
          DateTime(2026, 10, 26),
          rule: 'FREQ=WEEKLY;BYDAY=MO',
        ),
        event(
          '夜の予定',
          DateTime(2026, 11, 2, 23),
          DateTime(2026, 11, 3),
          allDay: false,
        ),
      ],
    );
    final days =
        (await usecase.execute('group', DateTime(2026, 11)))!['days'] as List;
    expect((days[1]['events'] as List).map((e) => e['title']), ['毎週', '夜の予定']);
    expect(days[2]['events'], isEmpty);
    expect(days[8]['events'].single['title'], '毎週');
    final firstOccurrence = days[1]['events'][0];
    final secondOccurrence = days[8]['events'].single;
    expect(firstOccurrence['id'], secondOccurrence['id']);
    expect(
      DateTime.parse(firstOccurrence['occurrence'] as String),
      DateTime.utc(2026, 11, 2),
    );
    expect(
      DateTime.parse(secondOccurrence['occurrence'] as String),
      DateTime.utc(2026, 11, 9),
    );
    expect(days[1]['events'][1]['isAllDay'], isFalse);
  });

  test('削除・アーカイブ済みグループは取得しない', () async {
    when(groups.getGroupWithMembersById('group')).thenAnswer((_) async => null);
    expect(await usecase.execute('group', DateTime(2026, 11)), isNull);
    verifyNever(events.getCalendarEventsByGroupId(any));
  });
}
