import 'package:memora/presentation/notifiers/startup/startup_common_data_notifier.dart';
import 'package:memora/composition_root/providers/startup_common_data_providers.dart';
import 'package:memora/presentation/notifiers/timeline/group_timeline_group_selection_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_preferences_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notification_preferences_notifier.dart';
import 'package:memora/presentation/app/startup_background_tasks.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_group_settings_notifier.dart';
import 'package:memora/presentation/app/app_availability_gate.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifications_notifier.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/app_bootstrap.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memora/presentation/app/app_theme.dart';
import 'package:memora/presentation/notifiers/setting/theme_settings_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/app/app_router.dart';
import 'package:memora/presentation/notifiers/android_widget/android_widget_launch_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_launch_notifier.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  await launchApp(
    const AppClockLifecycleSync(child: AppAvailabilityGate(child: MyApp())),
  );
}

class AppClockLifecycleSync extends ConsumerStatefulWidget {
  const AppClockLifecycleSync({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppClockLifecycleSync> createState() =>
      _AppClockLifecycleSyncState();
}

class _AppClockLifecycleSyncState extends ConsumerState<AppClockLifecycleSync>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncClock());
    }
  }

  Future<void> _syncClock() async {
    try {
      await ref.read(appClockProvider).sync();
    } catch (e, stack) {
      logger.w('NTP時刻の再同期に失敗しました', error: e, stackTrace: stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(startupCommonDataNotifierProvider, (_, next) {
      final groups = next.data.groups;
      final member = ref.read(startupCommonDataMemberIdProvider);
      if (groups == null && member != null && next.error.isNotEmpty) {
        ref
            .read(groupTimelineGroupSelectionNotifierProvider.notifier)
            .setLoadError(
              memberId: member,
              message: 'グループを取得できませんでした。再試行してください',
            );
      } else if (groups != null && member != null) {
        ref
            .read(groupTimelineGroupSelectionNotifierProvider.notifier)
            .setLoadedGroups(memberId: member, groups: groups);
      }
    });
    ref.watch(calendarPreferencesNotifierProvider);
    ref.watch(calendarNotificationPreferencesNotifierProvider);
    ref.watch(androidWidgetLaunchNotifierProvider);
    ref.watch(calendarLaunchNotifierProvider);
    ref.watch(calendarNotificationsNotifierProvider);
    ref.watch(calendarGroupSettingsNotifierProvider);
    return MaterialApp.router(
      builder: (context, child) => StartupBackgroundRegistrationNotice(
        child: child ?? const SizedBox.shrink(),
      ),
      routerConfig: ref.watch(appRouterConfigProvider),
      title: ref.watch(appDisplayNameProvider),
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: resolveAppThemeMode(
        ref.watch(
          themeSettingsNotifierProvider.select((value) => value.value?.mode),
        ),
      ),
      locale: const Locale('ja'),
      supportedLocales: const [Locale('ja'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
