// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'startup_background_tasks_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StartupBackgroundTasksNotifier)
final startupBackgroundTasksNotifierProvider =
    StartupBackgroundTasksNotifierProvider._();

final class StartupBackgroundTasksNotifierProvider
    extends
        $NotifierProvider<
          StartupBackgroundTasksNotifier,
          StartupBackgroundTasksState
        > {
  StartupBackgroundTasksNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startupBackgroundTasksNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startupBackgroundTasksNotifierHash();

  @$internal
  @override
  StartupBackgroundTasksNotifier create() => StartupBackgroundTasksNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StartupBackgroundTasksState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StartupBackgroundTasksState>(value),
    );
  }
}

String _$startupBackgroundTasksNotifierHash() =>
    r'7d8119bfc82bcb5c026d5e24c8fee38faa61c275';

abstract class _$StartupBackgroundTasksNotifier
    extends $Notifier<StartupBackgroundTasksState> {
  StartupBackgroundTasksState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<StartupBackgroundTasksState, StartupBackgroundTasksState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                StartupBackgroundTasksState,
                StartupBackgroundTasksState
              >,
              StartupBackgroundTasksState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
