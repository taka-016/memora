import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/services/calendar/calendar_notification_gateway.dart';
import 'package:memora/application/services/calendar/calendar_notification_source.dart';
import 'package:memora/application/usecases/calendar/synchronize_calendar_notifications_usecase.dart';
import 'package:memora/composition_root/providers/calendar_notification_providers.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifications_notifier.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';
import '../../../../helpers/test_exception.dart';
import 'calendar_notifications_notifier_test.mocks.dart';

@GenerateMocks([CalendarNotificationSource, SynchronizeCalendarNotificationsUsecase])
void main() {
  late ProviderContainer container;
  late MockCalendarNotificationSource source;
  late MockSynchronizeCalendarNotificationsUsecase sync;
  late StreamController<void> changes;
  setUp(() {
    changes = StreamController<void>.broadcast();
    source = MockCalendarNotificationSource();
    sync = MockSynchronizeCalendarNotificationsUsecase();
    when(source.changes()).thenAnswer((_) => changes.stream);
    when(sync.execute()).thenAnswer((_) async => CalendarNotificationStatus.ready);
    container = ProviderContainer(overrides: [
      calendarNotificationsSupportedProvider.overrideWithValue(true),
      calendarNotificationSourceProvider.overrideWithValue(source),
      synchronizeCalendarNotificationsUsecaseProvider.overrideWithValue(sync),
      currentMemberNotifierProvider.overrideWith(_CurrentMember.new),
    ]);
  });
  tearDown(() async { container.dispose(); await changes.close(); });
  test('ログアウトのloading遷移でも旧アカウントの購読と通知予約を更新する', () async {
    container.read(calendarNotificationsNotifierProvider);
    await container.pump();
    clearInteractions(sync);
    clearInteractions(source);
    container.read(currentMemberNotifierProvider.notifier).state = const CurrentMemberState.loading();
    await container.pump();
    verify(source.changes()).called(1);
    verify(sync.execute()).called(1);
  });
  test('監視失敗後の再試行は購読を張り直して以後の変更を受信する', () async {
    final notifier = container.read(calendarNotificationsNotifierProvider.notifier);
    await container.pump();
    changes.addError(TestException('監視失敗'));
    await container.pump();
    expect(container.read(calendarNotificationsNotifierProvider).status, CalendarNotificationStatus.failed);
    clearInteractions(source);
    await notifier.retry();
    await container.pump();
    verify(source.changes()).called(1);
    clearInteractions(sync);
    changes.add(null);
    await container.pump();
    verify(sync.execute()).called(1);
  });
}

class _CurrentMember extends CurrentMemberNotifier {
  @override
  CurrentMemberState build() => const CurrentMemberState.loaded(null);
}
