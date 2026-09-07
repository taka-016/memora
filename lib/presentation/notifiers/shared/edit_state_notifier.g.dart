// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edit_state_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EditStateNotifier)
final editStateNotifierProvider = EditStateNotifierProvider._();

final class EditStateNotifierProvider
    extends $NotifierProvider<EditStateNotifier, EditState> {
  EditStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'editStateNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$editStateNotifierHash();

  @$internal
  @override
  EditStateNotifier create() => EditStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EditState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EditState>(value),
    );
  }
}

String _$editStateNotifierHash() => r'fcc7e909280fa28e94a6a3b3d0c591426c072543';

abstract class _$EditStateNotifier extends $Notifier<EditState> {
  EditState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EditState, EditState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EditState, EditState>,
              EditState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
