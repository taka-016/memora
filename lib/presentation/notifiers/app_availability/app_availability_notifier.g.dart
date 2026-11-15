// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_availability_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppAvailabilityNotifier)
final appAvailabilityNotifierProvider = AppAvailabilityNotifierProvider._();

final class AppAvailabilityNotifierProvider
    extends $NotifierProvider<AppAvailabilityNotifier, AppAvailabilityState> {
  AppAvailabilityNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appAvailabilityNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appAvailabilityNotifierHash();

  @$internal
  @override
  AppAvailabilityNotifier create() => AppAvailabilityNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppAvailabilityState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppAvailabilityState>(value),
    );
  }
}

String _$appAvailabilityNotifierHash() =>
    r'9a07a3b4ea2a02a2460b78b26156a2c7ed1e1783';

abstract class _$AppAvailabilityNotifier
    extends $Notifier<AppAvailabilityState> {
  AppAvailabilityState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppAvailabilityState, AppAvailabilityState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppAvailabilityState, AppAvailabilityState>,
              AppAvailabilityState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
