import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/app_availability.dart';
import 'package:memora/application/usecases/app_availability/check_app_availability_usecase.dart';
import 'package:memora/composition_root/providers/app_availability_providers.dart';
import 'package:memora/presentation/notifiers/app_availability/app_availability_notifier.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'app_availability_notifier_test.mocks.dart';

@GenerateMocks([CheckAppAvailabilityUsecase])
void main() {
  late MockCheckAppAvailabilityUsecase check;
  late ProviderContainer container;

  setUp(() {
    check = MockCheckAppAvailabilityUsecase();
    container = ProviderContainer(
      overrides: [checkAppAvailabilityUsecaseProvider.overrideWithValue(check)],
    );
  });

  testWidgets('4回失敗してもエラーを表示せず5回目の成功で利用可能になる', (tester) async {
    addTearDown(container.dispose);
    var attempts = 0;
    when(check.execute()).thenAnswer((_) async {
      if (++attempts < 5) throw TestException('一時的な通信失敗');
      return AppAvailability.available;
    });
    container.read(appAvailabilityNotifierProvider);
    await tester.pump();
    for (var attempt = 1; attempt < 5; attempt++) {
      final state = container.read(appAvailabilityNotifierProvider);
      expect(state.isChecking, isTrue);
      expect(state.hasError, isFalse);
      expect(state.canUseApp, isFalse);
      expect(attempts, attempt);
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(container.read(appAvailabilityNotifierProvider).canUseApp, isTrue);
    expect(attempts, 5);
  });

  testWidgets('5回失敗して初めてエラーにし手動再確認では回数をリセットする', (tester) async {
    addTearDown(container.dispose);
    when(check.execute()).thenThrow(TestException('通信失敗'));
    container.read(appAvailabilityNotifierProvider);
    await tester.pump();
    for (var attempt = 1; attempt < 5; attempt++) {
      expect(container.read(appAvailabilityNotifierProvider).hasError, isFalse);
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(container.read(appAvailabilityNotifierProvider).hasError, isTrue);
    verify(check.execute()).called(5);
    when(check.execute()).thenAnswer((_) async => AppAvailability.available);
    final retry = container
        .read(appAvailabilityNotifierProvider.notifier)
        .refresh();
    await tester.pump();
    await retry;
    expect(container.read(appAvailabilityNotifierProvider).canUseApp, isTrue);
  });

  testWidgets('自動再試行中の再確認は処理を重ねず破棄後は再試行しない', (tester) async {
    when(check.execute()).thenThrow(TestException('通信失敗'));
    final notifier = container.read(appAvailabilityNotifierProvider.notifier);
    await tester.pump();
    final first = notifier.refresh();
    expect(identical(first, notifier.refresh()), isTrue);
    verify(check.execute()).called(1);
    container.dispose();
    await tester.pump(const Duration(milliseconds: 500));
    await first;
    verifyNever(check.execute());
  });
}
