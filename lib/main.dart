import 'package:memora/presentation/notifiers/calendar/calendar_notifications_notifier.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/app_bootstrap.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/app/app_router.dart';
import 'package:memora/presentation/notifiers/android_widget/android_widget_launch_notifier.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  await launchApp(const AppClockLifecycleSync(child: MyApp()));
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
      unawaited(
        ref.read(calendarNotificationsNotifierProvider.notifier).refresh(),
      );
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
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
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

ThemeData _buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: Colors.lightBlue,
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
    ),
    buttonTheme: const ButtonThemeData(alignedDropdown: true),
  );
}
