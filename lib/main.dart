import 'package:memora/presentation/notifiers/app_availability/app_availability_notifier.dart';
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

import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  await launchApp(
    const AppClockLifecycleSync(
      child: AppAvailabilityGate(child: _AvailableApp()),
    ),
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
    ref.watch(androidWidgetLaunchNotifierProvider);
    ref.watch(calendarNotificationsNotifierProvider);
    return MaterialApp.router(
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

class _AvailableApp extends ConsumerWidget {
  const _AvailableApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(appAvailabilityNotifierProvider, (previous, next) {
      unawaited(
        ref
            .read(calendarNotificationsNotifierProvider.notifier)
            .setSuspended(!next.canUseApp),
      );
    });
    return const MyApp();
  }
}
