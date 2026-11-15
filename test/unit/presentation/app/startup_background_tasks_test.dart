import 'package:shared_preferences/shared_preferences.dart';
import 'package:memora/application/models/app_theme_mode.dart';
import 'package:memora/composition_root/providers/theme_providers.dart';
import 'package:memora/presentation/app/app_availability_gate.dart';
import 'package:memora/composition_root/providers/app_availability_providers.dart';
import 'package:memora/application/usecases/app_availability/check_app_availability_usecase.dart';
import 'package:mockito/mockito.dart';
import 'app_availability_gate_test.mocks.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/composition_root/providers/background_task_providers.dart';
import 'package:memora/composition_root/startup_background_registration.dart';
import 'package:memora/presentation/app/startup_background_tasks.dart';

import '../../../helpers/test_exception.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('初期登録を待たず入力でき失敗した機能を表示した後もコンテナと入力を保持する', (tester) async {
    final ready = Completer<void>();
    var disposed = false;
    final registration = StartupBackgroundRegistration(
      loadRegistered: (_) async => false,
      markRegistered: (_) async {},
      initialize: () => ready.future,
      registerNotifications: () async {},
      loadWidgetInterval: () async => const Duration(minutes: 30),
      registerWidget: (_) async => throw TestException('ウィジェット登録失敗'),
    );
    final container = ProviderContainer(overrides: [
      startupBackgroundRegistrationProvider.overrideWith((ref) {
        ref.onDispose(() => disposed = true);
        return registration;
      }),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const StartupBackgroundTasks(
        child: MaterialApp(
          home: StartupBackgroundRegistrationNotice(
            child: Scaffold(body: TextField()),
          ),
        ),
      ),
    ));
    await tester.enterText(find.byType(TextField), '入力中');
    expect(find.textContaining('登録できませんでした'), findsNothing);
    ready.complete();
    await tester.pump();
    expect(find.textContaining('ウィジェット'), findsOneWidget);
    expect(disposed, isFalse);
    expect(find.text('入力中'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '入力を継続');
    await tester.tap(find.text('閉じる'));
    await tester.pump();
    expect(find.textContaining('登録できませんでした'), findsNothing);
    expect(find.text('入力を継続'), findsOneWidget);
  });

  testWidgets('登録済みの通常再登録は初回表示から3秒待って実行する', (tester) async {
    final calls = <String>[];
    final registration = StartupBackgroundRegistration(
      loadRegistered: (_) async => true,
      markRegistered: (_) async {},
      initialize: () async => calls.add('初期化'),
      registerNotifications: () async => calls.add('通知'),
      loadWidgetInterval: () async => const Duration(minutes: 30),
      registerWidget: (_) async => calls.add('ウィジェット'),
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [startupBackgroundRegistrationProvider.overrideWithValue(registration)],
      child: const StartupBackgroundTasks(child: SizedBox.shrink()),
    ));
    await tester.pump();
    expect(calls, isEmpty);
    await tester.pump(const Duration(seconds: 2));
    expect(calls, isEmpty);
    await tester.pump(const Duration(seconds: 1));
    expect(calls, ['初期化', '通知', 'ウィジェット']);
  });
  testWidgets('テーマ読み込みで初回描画が保留されている間は通常再登録の遅延を開始しない', (tester) async {
    final calls = <String>[];
    final theme = Completer<AppThemeMode>();
    final storage = MockAppThemeModeStorage();
    when(storage.load()).thenAnswer((_) => theme.future);
    final registration = StartupBackgroundRegistration(
      loadRegistered: (_) async => true,
      markRegistered: (_) async {},
      initialize: () async => calls.add('初期化'),
      registerNotifications: () async => calls.add('通知'),
      loadWidgetInterval: () async => const Duration(minutes: 30),
      registerWidget: (_) async => calls.add('ウィジェット'),
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        startupBackgroundRegistrationProvider.overrideWithValue(registration),
        appThemeModeStorageProvider.overrideWithValue(storage),
        checkAppAvailabilityUsecaseProvider.overrideWithValue(const CheckAppAvailabilityUsecase.unrestricted()),
      ],
      child: const StartupBackgroundTasks(child: AppAvailabilityGate(child: SizedBox.shrink())),
    ));
    await tester.pump(const Duration(seconds: 5));
    expect(calls, isEmpty);
    theme.complete(AppThemeMode.system);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(calls, ['初期化', '通知', 'ウィジェット']);
  });

}
