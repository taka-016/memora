import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/notifiers/trip/task_copy_notifier.dart';

void main() {
  test('コピー元旅行IDを設定・参照・変更・解除できる', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(copiedTaskTripIdProvider), isNull);

    final notifier = container.read(copiedTaskTripIdProvider.notifier);
    notifier.setTripId('trip-1');
    expect(container.read(copiedTaskTripIdProvider), 'trip-1');

    notifier.setTripId('trip-2');
    expect(container.read(copiedTaskTripIdProvider), 'trip-2');

    notifier.setTripId(null);
    expect(container.read(copiedTaskTripIdProvider), isNull);
  });

  test('Providerをoverrideしてコピー元を差し替えても変更・解除できる', () {
    final container = ProviderContainer(
      overrides: [
        copiedTaskTripIdProvider.overrideWith(_InitiallyCopiedTaskNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(copiedTaskTripIdProvider), 'copied-trip');

    final notifier = container.read(copiedTaskTripIdProvider.notifier);
    notifier.setTripId('another-trip');
    expect(container.read(copiedTaskTripIdProvider), 'another-trip');

    notifier.setTripId(null);
    expect(container.read(copiedTaskTripIdProvider), isNull);
  });
}

class _InitiallyCopiedTaskNotifier extends TaskCopyNotifier {
  @override
  String? build() => 'copied-trip';
}
