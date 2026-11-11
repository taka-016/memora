import 'package:memora/application/dtos/member/member_dto.dart';

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

@GenerateMocks([
  CalendarNotificationGateway,
  CalendarNotificationSource,
  SynchronizeCalendarNotificationsUsecase,
])
void main() {
  late ProviderContainer container;
  late MockCalendarNotificationSource source;
  late MockCalendarNotificationGateway gateway;
  late MockSynchronizeCalendarNotificationsUsecase sync;
  late StreamController<void> changes;
  setUp(() {
    changes = StreamController<void>.broadcast();
    source = MockCalendarNotificationSource();
    gateway = MockCalendarNotificationGateway();
    when(gateway.replace(any)).thenAnswer((_) async {});
    when(gateway.isEnabled()).thenAnswer((_) async => true);
    sync = MockSynchronizeCalendarNotificationsUsecase();
    when(source.changes()).thenAnswer((_) => changes.stream);
    when(sync.execute())
        .thenAnswer((_) async => CalendarNotificationStatus.ready);
    container = ProviderContainer(
      overrides: [
        calendarNotificationsSupportedProvider.overrideWithValue(true),
        calendarNotificationGatewayProvider.overrideWithValue(gateway),
        calendarNotificationSourceProvider.overrideWithValue(source),
        synchronizeCalendarNotificationsUsecaseProvider.overrideWithValue(sync),
        currentMemberNotifierProvider.overrideWith(_CurrentMember.new),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await changes.close();
  });
  test('通知が許可されていない間は監視せず再確認後に開始する', () async {
    when(gateway.isEnabled()).thenAnswer((_) async => false);
    final notifier = container.read(calendarNotificationsNotifierProvider.notifier);
    await container.pump();
    await Future<void>(() {});
    verifyNever(source.changes());
    when(gateway.isEnabled()).thenAnswer((_) async => true);
    await notifier.refresh();
    verify(source.changes()).called(1);
  });

  test('保存と復帰による同期で正常な監視を張り直さない', () async {
    final notifier = container.read(calendarNotificationsNotifierProvider.notifier);
    await container.pump();
    await Future<void>(() {});
    clearInteractions(source);
    await notifier.refresh();
    await notifier.refresh();
    verifyNever(source.changes());
  });

  test('スマートフォンの通知設定を開く間は処理中となり重複して開かない', () async {
    final opening = Completer<bool>();
    when(gateway.openNotificationSettings()).thenAnswer((_) => opening.future);
    final notifier = container.read(
      calendarNotificationsNotifierProvider.notifier,
    );
    await container.pump();
    await Future<void>(() {});
    final first = notifier.openNotificationSettings();
    expect(
      container.read(calendarNotificationsNotifierProvider).isSyncing,
      isTrue,
    );
    await notifier.openNotificationSettings();
    verify(gateway.openNotificationSettings()).called(1);
    opening.complete(true);
    await first;
    expect(
      container.read(calendarNotificationsNotifierProvider).isSyncing,
      isFalse,
    );
  });

  test('ログアウトのloading遷移でも旧アカウントの購読と通知予約を更新する', () async {
    container.read(calendarNotificationsNotifierProvider);
    await container.pump();
    await Future<void>(() {});
    clearInteractions(sync);
    clearInteractions(source);
    container.read(currentMemberNotifierProvider.notifier).state =
        const CurrentMemberState.loading();
    await container.pump();
    await Future<void>(() {});
    verifyNever(source.changes());
    verifyNever(sync.execute());
    verify(gateway.replace(argThat(isEmpty))).called(1);
  });
  test('監視失敗後の再試行は購読を張り直して以後の変更を受信する', () async {
    final notifier = container.read(
      calendarNotificationsNotifierProvider.notifier,
    );
    await container.pump();
    await Future<void>(() {});
    changes.addError(TestException('監視失敗'));
    await container.pump();
    await Future<void>(() {});
    expect(
      container.read(calendarNotificationsNotifierProvider).status,
      CalendarNotificationStatus.failed,
    );
    clearInteractions(source);
    await notifier.retry();
    await container.pump();
    await Future<void>(() {});
    verify(source.changes()).called(1);
    clearInteractions(sync);
    changes.add(null);
    await container.pump();
    await Future<void>(() {});
    verify(sync.execute()).called(1);
  });
}

class _CurrentMember extends CurrentMemberNotifier {
  @override
  CurrentMemberState build() =>
      const CurrentMemberState.loaded(MemberDto(id: 'self', displayName: '本人'));
}
