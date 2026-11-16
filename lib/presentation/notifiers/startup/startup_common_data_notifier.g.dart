// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'startup_common_data_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StartupCommonDataNotifier)
final startupCommonDataNotifierProvider = StartupCommonDataNotifierProvider._();

final class StartupCommonDataNotifierProvider
    extends
        $NotifierProvider<StartupCommonDataNotifier, StartupCommonDataState> {
  StartupCommonDataNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startupCommonDataNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startupCommonDataNotifierHash();

  @$internal
  @override
  StartupCommonDataNotifier create() => StartupCommonDataNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StartupCommonDataState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StartupCommonDataState>(value),
    );
  }
}

String _$startupCommonDataNotifierHash() =>
    r'e82a2231278200d64d9f4448c2f108f0cefa4988';

abstract class _$StartupCommonDataNotifier
    extends $Notifier<StartupCommonDataState> {
  StartupCommonDataState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<StartupCommonDataState, StartupCommonDataState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StartupCommonDataState, StartupCommonDataState>,
              StartupCommonDataState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
