import 'dart:async';

import 'package:go_router/go_router.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/models/app_availability.dart';
import 'package:memora/application/models/app_theme_mode.dart';
import 'package:memora/application/services/app_theme_mode_storage.dart';
import 'package:memora/composition_root/providers/theme_providers.dart';
import 'package:memora/application/usecases/app_availability/check_app_availability_usecase.dart';
import 'package:memora/composition_root/providers/app_availability_providers.dart';
import 'package:memora/presentation/app/app_availability_gate.dart';

import '../../../helpers/test_exception.dart';
import 'app_availability_gate_test.mocks.dart';

@GenerateMocks([CheckAppAvailabilityUsecase, AppThemeModeStorage])
void main() {
  late MockAppThemeModeStorage themeStorage;
  setUp(() {
    themeStorage = MockAppThemeModeStorage();
    when(themeStorage.load()).thenAnswer((_) async => AppThemeMode.system);
  });

  Widget createGate(
    CheckAppAvailabilityUsecase check, {
    Widget child = const SizedBox.shrink(),
  }) => ProviderScope(
    overrides: [
      checkAppAvailabilityUsecaseProvider.overrideWithValue(check),
      appThemeModeStorageProvider.overrideWithValue(themeStorage),
    ],
    child: AppAvailabilityGate(child: child),
  );

  for (final entry in [
    (AppThemeMode.dark, Brightness.light, Brightness.dark),
    (AppThemeMode.light, Brightness.dark, Brightness.light),
    (AppThemeMode.system, Brightness.dark, Brightness.dark),
  ]) {
    testWidgets(
      '停止案内は保存テーマ${entry.$1.name}と端末${entry.$2.name}から${entry.$3.name}で表示する',
      (tester) async {
        tester.binding.resetFirstFrameSent();
        final platform = tester.binding.platformDispatcher;
        platform.platformBrightnessTestValue = entry.$2;
        addTearDown(platform.clearPlatformBrightnessTestValue);
        when(themeStorage.load()).thenAnswer((_) async => entry.$1);
        final pending = Completer<AppAvailability>();
        final check = MockCheckAppAvailabilityUsecase();
        when(check.execute()).thenAnswer((_) => pending.future);
        await tester.pumpWidget(createGate(check));
        await tester.pump();
        expect(tester.binding.sendFramesToEngine, isTrue);
        pending.complete(AppAvailability.maintenance);
        await tester.pump();
        expect(find.text('メンテナンス中です'), findsOneWidget);
        expect(
          Theme.of(tester.element(find.byType(Scaffold))).brightness,
          entry.$3,
        );
        expect(tester.binding.sendFramesToEngine, isTrue);
      },
    );
  }

  testWidgets('テーマの読み込み後は利用可否の確認を待たず初回画面を表示する', (tester) async {
    tester.binding.resetFirstFrameSent();
    final themeReady = Completer<AppThemeMode>();
    when(themeStorage.load()).thenAnswer((_) => themeReady.future);
    final pending = Completer<AppAvailability>();
    final check = MockCheckAppAvailabilityUsecase();
    when(check.execute()).thenAnswer((_) => pending.future);
    var built = false;
    await tester.pumpWidget(
      createGate(
        check,
        child: Builder(
          builder: (_) {
            built = true;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(tester.binding.sendFramesToEngine, isFalse);
    expect(built, isFalse);
    themeReady.complete(AppThemeMode.dark);
    await tester.pump();
    expect(tester.binding.sendFramesToEngine, isTrue);
    expect(built, isTrue);
    pending.complete(AppAvailability.available);
    await tester.pump();
  });

  testWidgets('自動再試行を使い切ったらスプラッシュを終了し再確認できる', (tester) async {
    tester.binding.resetFirstFrameSent();
    final check = MockCheckAppAvailabilityUsecase();
    when(check.execute()).thenThrow(TestException('通信失敗'));
    await tester.pumpWidget(createGate(check));
    await tester.pump();
    expect(tester.binding.sendFramesToEngine, isTrue);
    for (var attempt = 1; attempt < 5; attempt++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('利用状況を確認できませんでした'), findsOneWidget);
    expect(tester.binding.sendFramesToEngine, isTrue);
    when(check.execute()).thenAnswer((_) async => AppAvailability.available);
    await tester.tap(find.text('再確認'));
    await tester.pump();
    expect(find.text('利用状況を確認できませんでした'), findsNothing);
  });

  testWidgets('起動確認中は画面を表示し更新案内から再確認して再開する', (tester) async {
    final check = MockCheckAppAvailabilityUsecase();
    final pending = Completer<AppAvailability>();
    when(check.execute()).thenAnswer((_) => pending.future);
    var built = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checkAppAvailabilityUsecaseProvider.overrideWithValue(check),
          appThemeModeStorageProvider.overrideWithValue(themeStorage),
        ],
        child: AppAvailabilityGate(
          child: Builder(
            builder: (_) {
              built = true;
              return const MaterialApp(home: Text('アプリ本体'));
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(built, isTrue);
    expect(find.text('利用状況を確認しています'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    pending.complete(AppAvailability.updateRequired);
    await tester.pump();
    expect(find.text('アプリの更新が必要です'), findsOneWidget);
    expect(built, isTrue);
    when(check.execute()).thenAnswer((_) async => AppAvailability.available);
    await tester.tap(find.text('再確認'));
    await tester.pump();
    expect(find.text('アプリ本体'), findsOneWidget);
  });

  testWidgets('復帰時の停止と取得失敗を表示し再試行後も入力を維持する', (tester) async {
    final check = MockCheckAppAvailabilityUsecase();
    when(check.execute()).thenAnswer((_) async => AppAvailability.available);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checkAppAvailabilityUsecaseProvider.overrideWithValue(check),
          appThemeModeStorageProvider.overrideWithValue(themeStorage),
        ],
        child: const AppAvailabilityGate(
          child: MaterialApp(home: Scaffold(body: TextField())),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), '編集中');
    when(check.execute()).thenAnswer((_) async => AppAvailability.maintenance);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('メンテナンス中です'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    when(check.execute()).thenThrow(TestException('通信失敗'));
    await tester.tap(find.text('再確認'));
    await tester.pump();
    for (var attempt = 1; attempt < 5; attempt++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('利用状況を確認できませんでした'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    when(check.execute()).thenAnswer((_) async => AppAvailability.available);
    await tester.tap(find.text('再確認'));
    await tester.pump();
    expect(find.text('編集中'), findsOneWidget);
  });
  testWidgets('復帰確認中も元の画面で操作を続ける', (tester) async {
    final check = MockCheckAppAvailabilityUsecase();
    when(check.execute()).thenAnswer((_) async => AppAvailability.available);
    var operations = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checkAppAvailabilityUsecaseProvider.overrideWithValue(check),
          appThemeModeStorageProvider.overrideWithValue(themeStorage),
        ],
        child: AppAvailabilityGate(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const Text('表示中の画面'),
                  TextButton(
                    onPressed: () => operations++,
                    child: const Text('操作'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final pending = Completer<AppAvailability>();
    when(check.execute()).thenAnswer((_) => pending.future);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('表示中の画面'), findsOneWidget);
    expect(find.text('利用状況を確認しています'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('操作'), warnIfMissed: false);
    expect(operations, 1);
    pending.complete(AppAvailability.available);
    await tester.pump();
    await tester.tap(find.text('操作'));
    expect(operations, 2);
  });

  testWidgets('確認失敗後も入力を続けられ再確認で内容を失わない', (tester) async {
    final check = MockCheckAppAvailabilityUsecase();
    final pending = Completer<AppAvailability>();
    when(check.execute()).thenAnswer((_) => pending.future);
    await tester.pumpWidget(
      createGate(
        check,
        child: const MaterialApp(home: Scaffold(body: TextField())),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), '入力中');
    when(check.execute()).thenThrow(TestException('通信失敗'));
    pending.completeError(TestException('通信失敗'));
    await tester.pump();
    for (var attempt = 1; attempt < 5; attempt++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('利用状況を確認できませんでした'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '入力を継続');
    when(check.execute()).thenAnswer((_) async => AppAvailability.available);
    await tester.tap(find.text('再確認'));
    await tester.pump();
    expect(find.text('入力を継続'), findsOneWidget);
  });

  testWidgets('停止中の戻る操作は隠れた編集中の画面を閉じない', (tester) async {
    final check = MockCheckAppAvailabilityUsecase();
    when(check.execute()).thenAnswer((_) async => AppAvailability.available);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('一覧')),
        ),
        GoRoute(
          path: '/edit',
          builder: (_, _) => const Scaffold(body: Text('編集中の画面')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checkAppAvailabilityUsecaseProvider.overrideWithValue(check),
          appThemeModeStorageProvider.overrideWithValue(themeStorage),
        ],
        child: AppAvailabilityGate(
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pump();
    router.push('/edit');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    when(check.execute()).thenAnswer((_) async => AppAvailability.maintenance);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    when(check.execute()).thenAnswer((_) async => AppAvailability.available);
    await tester.tap(find.text('再確認'));
    await tester.pump();
    expect(find.text('編集中の画面'), findsOneWidget);
  });
}
