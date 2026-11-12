import 'dart:async';

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
}
