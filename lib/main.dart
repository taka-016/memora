import 'package:memora/application/models/app_capabilities.dart';
import 'package:memora/composition_root/providers/app_capabilities_provider.dart';
import 'package:memora/presentation/app/application_unavailable_page.dart';
import 'package:memora/composition_root/app_bootstrap.dart';
import 'package:memora/composition_root/providers/app_clock_provider.dart';

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
    final storageAvailability = ref
        .watch(appCapabilitiesProvider)
        .availability(AppFeature.localData);
    if (!storageAvailability.isAvailable) {
      return MaterialApp(
        home: ApplicationUnavailablePage(reason: storageAvailability.reason!),
      );
    }
    ref.watch(androidWidgetLaunchNotifierProvider);
    return MaterialApp.router(
      routerConfig: ref.watch(appRouterConfigProvider),
      title: 'memora',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
        ),
        buttonTheme: const ButtonThemeData(alignedDropdown: true),
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
