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
    extends $NotifierProvider<StartupBackgroundTasksNotifier, List<String>> {
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
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$startupBackgroundTasksNotifierHash() =>
    r'116bf27a3aefa79db8cfce55aac3faee19f3d864';

abstract class _$StartupBackgroundTasksNotifier
    extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
