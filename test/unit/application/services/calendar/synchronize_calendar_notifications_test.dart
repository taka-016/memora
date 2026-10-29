import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/services/calendar/calendar_notification_gateway.dart';
import 'package:memora/application/services/calendar/calendar_notification_preferences.dart';
import 'package:memora/application/services/calendar/calendar_notification_planner.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_expander.dart';
import 'package:memora/application/usecases/calendar/synchronize_calendar_notifications_usecase.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/infrastructure/services/iana_calendar_time_zone.dart';
import '../../../../helpers/test_exception.dart';
import 'synchronize_calendar_notifications_test.mocks.dart';

@GenerateMocks([CalendarNotificationGateway, CalendarNotificationStorage])
void main() {
  late MockCalendarNotificationGateway gateway;
  late MockCalendarNotificationStorage storage;
  late SynchronizeCalendarNotificationsUsecase sync;
  final now = DateTime(2026, 10, 29);
  var events = <CalendarEventDto>[];
  setUp(() {
    gateway = MockCalendarNotificationGateway();
    storage = MockCalendarNotificationStorage();
    when(storage.load()).thenAnswer((_) async => const CalendarNotificationPreferences());
    when(gateway.isEnabled()).thenAnswer((_) async => true);
    when(gateway.replace(any)).thenAnswer((_) async {});
    events = [CalendarEventDto(id: 'other-author', groupId: 'joined', labelType: 'group', title: '他のメンバーの予定', startDateTime: DateTime(2026, 10, 30), endDateTime: DateTime(2026, 10, 30), isAllDay: true, notificationMinutesBefore: [0])];
    sync = SynchronizeCalendarNotificationsUsecase(loadEvents: () async => events, storage: storage, gateway: gateway, planner: CalendarNotificationPlanner(CalendarRecurrenceExpander(IanaCalendarTimeZone())), now: () => now);
  });
  test('登録者によらず取得した全予定を予約し削除後は古い予約を解除する', () async {
    expect(await sync.execute(), CalendarNotificationStatus.ready);
    final planned = verify(gateway.replace(captureAny)).captured.single as List<CalendarNotificationRequest>;
    expect(planned.single.title, '他のメンバーの予定');
    events = [];
    await sync.execute();
    verify(gateway.replace(argThat(isEmpty)));
  });
  test('権限がないときは予約を解除して権限なしを返す', () async {
    when(gateway.isEnabled()).thenAnswer((_) async => false);
    expect(await sync.execute(), CalendarNotificationStatus.denied);
    verify(gateway.replace(argThat(isEmpty)));
  });
  test('予約失敗は画面で確認できる状態を返し再試行で復旧する', () async {
    when(gateway.replace(any)).thenThrow(TestException('予約失敗'));
    expect(await sync.execute(), CalendarNotificationStatus.failed);
    when(gateway.replace(any)).thenAnswer((_) async {});
    expect(await sync.execute(), CalendarNotificationStatus.ready);
  });
}
