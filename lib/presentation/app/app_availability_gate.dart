import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/app_availability.dart';
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
      unawaited(ref.read(appAvailabilityNotifierProvider.notifier).refresh());
    }
  }

  @override
  Future<bool> didPopRoute() async =>
      !ref.read(appAvailabilityNotifierProvider).canUseApp;

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) =>
      !ref.read(appAvailabilityNotifierProvider).canUseApp;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appAvailabilityNotifierProvider);
    if (state.canUseApp) _started = true;
    final isCheckingAvailableApp =
        _started &&
        state.isChecking &&
        state.availability == AppAvailability.available;
    final message = state.hasError
        ? '利用状況を確認できませんでした'
        : switch (state.availability) {
            AppAvailability.updateRequired => 'アプリの更新が必要です',
            AppAvailability.maintenance => 'メンテナンス中です',
            _ => null,
          };
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        if (_started)
          Offstage(
            offstage: !state.canUseApp && !isCheckingAvailableApp,
            child: AbsorbPointer(
              absorbing: !state.canUseApp,
              child: TickerMode(
                enabled: state.canUseApp,
                child: ExcludeFocus(
                  excluding: !state.canUseApp,
                  child: widget.child,
                ),
              ),
            ),
          ),
        if (!state.canUseApp && !isCheckingAvailableApp)
          MaterialApp(
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
                        if (state.isChecking)
                          const CircularProgressIndicator()
                        else
                          FilledButton(
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
      ],
    );
  }
}
