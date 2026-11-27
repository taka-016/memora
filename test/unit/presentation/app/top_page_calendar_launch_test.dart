import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/calendar_event_draft_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_launch_request_dto.dart';
import 'package:memora/presentation/app/app_router.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_launch_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_group_settings_notifier.dart';
import 'package:memora/presentation/features/calendar/calendar_event_input_page.dart';
import 'package:memora/presentation/features/calendar/calendar_screen.dart';
import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/application/models/app_capabilities.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/presentation/notifiers/auth/auth_state.dart';

import '../../../helpers/calendar_group_settings_test_support.dart';
import '../../../helpers/fake_auth_notifier.dart';
import 'top_page_test_support.dart';

class _CalendarLaunch extends CalendarLaunchNotifier {
  @override
  CalendarLaunchState build() => const CalendarLaunchState();
  void receive(CalendarLaunchRequestDto request) {
    state = CalendarLaunchState(request: request, sequence: state.sequence + 1);
  }
}

class _Auth extends FakeAuthNotifier {
  _Auth() : super(const AuthState.unauthenticated(''));
  void authenticate() {
    state = const AuthState.authenticated(UserDto(id: 'test_user_id', loginId: 'test@example.com', isVerified: true));
  }
}

void main() {
  final context = TopPageTestContext();
  setUp(context.setUpContext);

  testWidgets('ログイン前に受け取った日時指定をログイン完了後に開く', (tester) async {
    final launch = _CalendarLaunch();
    final auth = _Auth();
    final container = ProviderContainer(overrides: [
      ...context.createTopPageTestOverrides(authNotifier: auth, initialLocation: '/settings'),
      appCapabilitiesProvider.overrideWithValue(AppCapabilities.forMode(AppMode.online)),
      calendarLaunchNotifierProvider.overrideWith(() => launch),
    ]);
    addTearDown(container.dispose);
    final router = container.read(appRouterConfigProvider);
    final date = DateTime(2026, 11, 28);
    container.read(calendarLaunchNotifierProvider);
    launch.receive(CalendarLaunchRequestDto(date: date));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    expect(router.state.uri.path, '/login');
    expect(container.read(calendarLaunchNotifierProvider).request, isNotNull);
    auth.authenticate();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(router.state.uri.path, '/calendar');
    expect(tester.widget<CalendarScreen>(find.byType(CalendarScreen)).initialDate, date);
  });

  testWidgets('起動済みの別画面から日時指定でカレンダーを開き同じ日付で再度開ける', (tester) async {
    final launch = _CalendarLaunch();
    final container = ProviderContainer(overrides: [
      ...context.createTopPageTestOverrides(initialLocation: '/settings'),
      calendarLaunchNotifierProvider.overrideWith(() => launch),
    ]);
    addTearDown(container.dispose);
    final router = container.read(appRouterConfigProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    final date = DateTime(2026, 11, 28);
    launch.receive(CalendarLaunchRequestDto(date: date));
    await tester.pump();
    await tester.pump();
    expect(tester.widget<CalendarScreen>(find.byType(CalendarScreen)).initialDate, date);
    final firstLocation = router.state.uri.toString();
    launch.receive(CalendarLaunchRequestDto(date: date));
    await tester.pump();
    await tester.pump();
    expect(router.state.uri.toString(), isNot(firstLocation));
    expect(container.read(calendarLaunchNotifierProvider).request, isNull);
  });

  testWidgets('予定追加の要求からタイトルと場所を引き継いだ新規入力画面を開く', (tester) async {
    final launch = _CalendarLaunch();
    final container = ProviderContainer(overrides: [
      ...context.createTopPageTestOverrides(initialLocation: '/settings'),
      calendarLaunchNotifierProvider.overrideWith(() => launch),
      calendarGroupSettingsNotifierProvider.overrideWith(() => TestCalendarGroupSettingsNotifier(defaultGroupId: null)),
    ]);
    addTearDown(container.dispose);
    final router = container.read(appRouterConfigProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    launch.receive(CalendarLaunchRequestDto(
      date: DateTime(2026, 11, 28, 9),
      draft: CalendarEventDraftDto(
        title: '予約 & 打合せ', locationName: '会議室A', memo: '資料\n持参',
        start: DateTime(2026, 11, 28, 9), end: DateTime(2026, 11, 28, 10),
      ),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.byType(CalendarEventInputPage), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '予約 & 打合せ'), findsOneWidget);
    final input = tester.widget<CalendarEventInputPage>(find.byType(CalendarEventInputPage));
    expect(input.event, isNull);
    expect(input.initialDraft!.locationName, '会議室A');
    expect(input.initialDraft!.memo, '資料\n持参');
  });
}
