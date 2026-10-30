import 'package:memora/composition_root/providers/calendar_notification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/services/calendar/calendar_notification_gateway.dart';
import 'package:memora/presentation/features/setting/calendar_notification_setting.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifications_notifier.dart';

void main() {
  Future<void> showStatus(WidgetTester tester, _StatusNotifier notifier) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarNotificationsSupportedProvider.overrideWithValue(true),
          calendarNotificationsNotifierProvider.overrideWith(() => notifier),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CalendarNotificationStatusView(),
            ),
          ),
        ),
      ),
    );
  }

  for (final initial in [
    const CalendarNotificationsState(isSyncing: true),
    const CalendarNotificationsState(status: CalendarNotificationStatus.ready),
    const CalendarNotificationsState(
      status: CalendarNotificationStatus.ready,
      isSyncing: true,
    ),
  ]) {
    testWidgets(
      '操作が不要なときは通知処理の状態や操作ボタンを表示しない（${initial.status}・更新中${initial.isSyncing}）',
      (tester) async {
        await showStatus(tester, _StatusNotifier(initial));
        expect(find.byType(Text), findsNothing);
        expect(find.byType(TextButton), findsNothing);
      },
    );
  }

  testWidgets('通知が許可されていない理由とスマートフォンの設定への入口を案内する', (tester) async {
    final notifier = _StatusNotifier(
      const CalendarNotificationsState(
        status: CalendarNotificationStatus.denied,
      ),
    );
    await showStatus(tester, notifier);
    expect(find.text('予定の通知が許可されていません'), findsOneWidget);
    expect(find.text('スマートフォンの設定で、このアプリの通知をオンにしてください。'), findsOneWidget);
    await tester.tap(find.text('スマートフォンの設定を開く'));
    await tester.pump();
    expect(notifier.settingsOpens, 1);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('失敗時は通知が届かない可能性を説明し通知を設定し直せる', (tester) async {
    final notifier = _StatusNotifier(
      const CalendarNotificationsState(
        status: CalendarNotificationStatus.failed,
      ),
    );
    await showStatus(tester, notifier);
    expect(find.text('予定の通知を設定できませんでした'), findsOneWidget);
    expect(find.text('予定で設定した通知が届かない可能性があります。'), findsOneWidget);
    await tester.tap(find.text('通知を設定し直す'));
    await tester.pump();
    expect(notifier.retries, 1);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('通知を設定し直している間は処理中と分かり重複操作できない', (tester) async {
    final notifier = _StatusNotifier(
      const CalendarNotificationsState(
        status: CalendarNotificationStatus.failed,
        isSyncing: true,
      ),
    );
    await showStatus(tester, notifier);
    expect(find.text('設定中…'), findsOneWidget);
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
    expect(notifier.retries, 0);
  });
}

class _StatusNotifier extends CalendarNotificationsNotifier {
  _StatusNotifier(this.initial);
  final CalendarNotificationsState initial;
  int settingsOpens = 0;
  int retries = 0;

  @override
  CalendarNotificationsState build() => initial;

  @override
  Future<void> openNotificationSettings() async {
    settingsOpens++;
    state = const CalendarNotificationsState(
      status: CalendarNotificationStatus.ready,
    );
  }

  @override
  Future<void> retry() async {
    retries++;
    state = const CalendarNotificationsState(
      status: CalendarNotificationStatus.ready,
    );
  }
}
