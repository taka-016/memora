import 'package:memora/application/exceptions/application_validation_exception.dart';

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
  bool get isBlocked =>
      availability == AppAvailability.maintenance ||
      availability == AppAvailability.updateRequired;
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

  Future<void> ensureAvailable() async {
    if (state.isChecking || (state.availability == null && !state.hasError)) {
      await refresh();
    }
    if (!ref.mounted || !state.canUseApp) {
      throw const ApplicationValidationException(
        '利用可能と確認できないため保存できません。利用状況を再確認してください。',
      );
    }
  }

  Future<void> _check() async {
    try {
      for (var attempt = 0; attempt < 5; attempt++) {
        if (!ref.mounted) return;
        try {
          final result = await ref
              .read(checkAppAvailabilityUsecaseProvider)
              .execute();
          if (ref.mounted) state = AppAvailabilityState(availability: result);
          return;
        } catch (_) {
          if (!ref.mounted) return;
          if (attempt == 4) {
            state = AppAvailabilityState(availability: state.availability, hasError: true);
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
    } finally {
      _pending = null;
    }
  }
}
