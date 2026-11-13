import 'dart:async';

import 'package:go_router/go_router.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/models/app_availability.dart';
import 'package:memora/application/usecases/app_availability/check_app_availability_usecase.dart';
import 'package:memora/composition_root/providers/app_availability_providers.dart';
import 'package:memora/presentation/app/app_availability_gate.dart';

import '../../../helpers/test_exception.dart';
import 'app_availability_gate_test.mocks.dart';

@GenerateMocks([CheckAppAvailabilityUsecase])
void main() {
  testWidgets('起動確認中は機能を開始せず更新案内から再確認して再開する', (tester) async {
    final check = MockCheckAppAvailabilityUsecase();
    final pending = Completer<AppAvailability>();
    when(check.execute()).thenAnswer((_) => pending.future);
    var built = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checkAppAvailabilityUsecaseProvider.overrideWithValue(check),
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
    expect(built, isFalse);
    expect(find.text('利用状況を確認しています'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(AppAvailability.updateRequired);
    await tester.pump();
    expect(find.text('アプリの更新が必要です'), findsOneWidget);
    expect(built, isFalse);
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
    expect(find.text('利用状況を確認できませんでした'), findsOneWidget);
    when(check.execute()).thenAnswer((_) async => AppAvailability.available);
    await tester.tap(find.text('再確認'));
    await tester.pump();
    expect(find.text('編集中'), findsOneWidget);
  });
  testWidgets('復帰確認中は元の画面を表示したまま操作を止める', (tester) async {
    final check = MockCheckAppAvailabilityUsecase();
    when(check.execute()).thenAnswer((_) async => AppAvailability.available);
    var operations = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checkAppAvailabilityUsecaseProvider.overrideWithValue(check),
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
    expect(operations, 0);
    pending.complete(AppAvailability.available);
    await tester.pump();
    await tester.tap(find.text('操作'));
    expect(operations, 1);
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
