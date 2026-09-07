// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_copy_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TaskCopyNotifier)
final copiedTaskTripIdProvider = TaskCopyNotifierProvider._();

final class TaskCopyNotifierProvider
    extends $NotifierProvider<TaskCopyNotifier, String?> {
  TaskCopyNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'copiedTaskTripIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskCopyNotifierHash();

  @$internal
  @override
  TaskCopyNotifier create() => TaskCopyNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$taskCopyNotifierHash() => r'b28a8861561a99b2f8455d9b5c046b6b0b7830f5';

abstract class _$TaskCopyNotifier extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
