import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/app_availability.dart';
import 'package:memora/presentation/app/app_theme.dart';
import 'package:memora/presentation/notifiers/setting/theme_settings_notifier.dart';
import 'package:memora/presentation/notifiers/app_availability/app_availability_notifier.dart';

class AppAvailabilityGate extends ConsumerStatefulWidget {
  const AppAvailabilityGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppAvailabilityGate> createState() =>
      _AppAvailabilityGateState();
}

class _AppAvailabilityGateState extends ConsumerState<AppAvailabilityGate>
    with WidgetsBindingObserver {
  bool _started = false;
  bool _firstFrameDeferred = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.deferFirstFrame();
    ref.listenManual(
      themeSettingsNotifierProvider,
      (_, _) => _maybeAllowFirstFrame(),
    );
    _maybeAllowFirstFrame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _allowFirstFrame();
    super.dispose();
  }

  void _maybeAllowFirstFrame() {
    if (!_firstFrameDeferred || !mounted) return;
    if (ref.read(themeSettingsNotifierProvider).isLoading) {
      return;
    }
    _allowFirstFrame();
  }

  void _allowFirstFrame() {
    if (!_firstFrameDeferred) return;
    _firstFrameDeferred = false;
    WidgetsBinding.instance.allowFirstFrame();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(appAvailabilityNotifierProvider.notifier).refresh());
    }
  }

  @override
  Future<bool> didPopRoute() async =>
      ref.read(appAvailabilityNotifierProvider).isBlocked;

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) =>
      ref.read(appAvailabilityNotifierProvider).isBlocked;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appAvailabilityNotifierProvider);
    final themeState = ref.watch(themeSettingsNotifierProvider);
    if (!themeState.isLoading) _started = true;
    final message = state.hasError
        ? '利用状況を確認できませんでした'
        : switch (state.availability) {
            AppAvailability.updateRequired => 'アプリの更新が必要です',
            AppAvailability.maintenance => 'メンテナンス中です',
            _ => null,
          };
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          if (_started)
            Offstage(
              offstage: state.isBlocked,
              child: AbsorbPointer(
                absorbing: state.isBlocked,
                child: TickerMode(
                  enabled: !state.isBlocked,
                  child: ExcludeFocus(
                    excluding: state.isBlocked,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          if (_started && state.hasError && !state.isBlocked)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Theme(
                data: buildAppTheme(
                  resolveAppThemeMode(themeState.value?.mode) ==
                              ThemeMode.dark ||
                          (resolveAppThemeMode(themeState.value?.mode) ==
                                  ThemeMode.system &&
                              MediaQuery.platformBrightnessOf(context) ==
                                  Brightness.dark)
                      ? Brightness.dark
                      : Brightness.light,
                ),
                child: Material(
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Expanded(child: Text('利用状況を確認できませんでした')),
                          TextButton(
                            onPressed: () => ref
                                .read(appAvailabilityNotifierProvider.notifier)
                                .refresh(),
                            child: const Text('再確認'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (!_started || state.isBlocked)
            MaterialApp(
              theme: buildAppTheme(Brightness.light),
              darkTheme: buildAppTheme(Brightness.dark),
              themeMode: resolveAppThemeMode(themeState.value?.mode),
              themeAnimationDuration: Duration.zero,
              home: Scaffold(
                body: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message != null) ...[
                            Text(
                              message,
                              style: const TextStyle(fontSize: 22),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (state.availability ==
                              AppAvailability.updateRequired)
                            const Text(
                              '配布元から最新版に更新してください。',
                              textAlign: TextAlign.center,
                            ),
                          if (state.availability == AppAvailability.maintenance)
                            const Text(
                              'しばらく待ってから再確認してください。',
                              textAlign: TextAlign.center,
                            ),
                          if (state.hasError)
                            const Text(
                              '通信環境を確認して再確認してください。',
                              textAlign: TextAlign.center,
                            ),
                          if (message != null) const SizedBox(height: 16),
                          if (state.isChecking || themeState.isLoading)
                            const CircularProgressIndicator()
                          else
                            FilledButton(
                              onPressed: () => ref
                                  .read(
                                    appAvailabilityNotifierProvider.notifier,
                                  )
                                  .refresh(),
                              child: const Text('再確認'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
