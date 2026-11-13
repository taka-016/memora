import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memora/application/models/app_availability.dart';
import 'package:memora/composition_root/providers/app_availability_providers.dart';

part 'app_availability_notifier.g.dart';

class AppAvailabilityState {
  const AppAvailabilityState({
    this.availability,
    this.isChecking = false,
    this.hasError = false,
  });

  final AppAvailability? availability;
  final bool isChecking;
  final bool hasError;
  bool get canUseApp =>
      !isChecking && !hasError && availability == AppAvailability.available;
}

@Riverpod(keepAlive: true)
class AppAvailabilityNotifier extends _$AppAvailabilityNotifier {
  Future<void>? _pending;

  @override
  AppAvailabilityState build() {
    Future.microtask(() {
      if (ref.mounted) unawaited(refresh());
    });
    return const AppAvailabilityState(isChecking: true);
  }

  Future<void> refresh() {
    final pending = _pending;
    if (pending != null) return pending;
    state = AppAvailabilityState(
      availability: state.availability,
      isChecking: true,
    );
    return _pending = Future.microtask(_check);
  }

  Future<void> _check() async {
    try {
      final result = await ref
          .read(checkAppAvailabilityUsecaseProvider)
          .execute();
      if (ref.mounted) state = AppAvailabilityState(availability: result);
    } catch (_) {
      if (ref.mounted) state = const AppAvailabilityState(hasError: true);
    } finally {
      _pending = null;
    }
  }
}
