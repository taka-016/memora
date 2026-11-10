import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/application/usecases/calendar/get_calendar_events_usecase.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/member/get_current_member_usecase.dart';
import 'package:memora/infrastructure/services/calendar_notification_source.dart';
import 'package:memora/infrastructure/time/fixed_app_clock.dart';

import 'calendar_notification_source_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GetCurrentMemberUseCase>(),
  MockSpec<GetGroupsWithMembersUsecase>(),
  MockSpec<GetCalendarEventsUsecase>(),
])
void main() {
  test('通知用の全所属グループ取得へ現在の通知対象期間を渡す', () async {
    final currentMember = MockGetCurrentMemberUseCase();
    final groups = MockGetGroupsWithMembersUsecase();
    final events = MockGetCalendarEventsUsecase();
    const member = MemberDto(id: 'm', displayName: '本人');
    when(currentMember.execute()).thenAnswer((_) async => member);
    when(groups.execute(member)).thenAnswer(
      (_) async => [
        const GroupDto(id: 'g1', ownerId: 'm', name: '家族'),
        const GroupDto(id: 'g2', ownerId: 'other', name: '友人'),
      ],
    );
    final now = DateTime(2026, 11, 10, 15);
    final source = DeviceCalendarNotificationSource(
      currentMember: currentMember,
      groups: groups,
      events: events,
      clock: FixedAppClock(now),
    );
    await source.load();
    final period = CalendarEventPeriod.forNotifications(now);
    verify(events.execute('g1', period: period)).called(1);
    verify(events.execute('g2', period: period)).called(1);
    verifyNoMoreInteractions(events);
  });
}
