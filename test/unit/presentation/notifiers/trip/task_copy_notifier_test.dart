import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/notifiers/trip/task_copy_notifier.dart';

void main() {
  test('コピー元旅行IDを設定・参照・変更・解除できる', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(copiedTaskTripIdProvider), isNull);

    final notifier = container.read(copiedTaskTripIdProvider.notifier);
    notifier.state = 'trip-1';
    expect(container.read(copiedTaskTripIdProvider), 'trip-1');

    notifier.state = 'trip-2';
    expect(container.read(copiedTaskTripIdProvider), 'trip-2');

    notifier.state = null;
    expect(container.read(copiedTaskTripIdProvider), isNull);
  });

  test('Providerをoverrideしてコピー元を差し替えても変更・解除できる', () {
    final container = ProviderContainer(
      overrides: [
        copiedTaskTripIdProvider.overrideWith((ref) => 'copied-trip'),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(copiedTaskTripIdProvider), 'copied-trip');

    final notifier = container.read(copiedTaskTripIdProvider.notifier);
    notifier.state = 'another-trip';
    expect(container.read(copiedTaskTripIdProvider), 'another-trip');

    notifier.state = null;
    expect(container.read(copiedTaskTripIdProvider), isNull);
  });
}
