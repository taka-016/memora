// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_backup_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OfflineBackupNotifier)
final offlineBackupNotifierProvider = OfflineBackupNotifierProvider._();

final class OfflineBackupNotifierProvider
    extends $NotifierProvider<OfflineBackupNotifier, OfflineBackupState> {
  OfflineBackupNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offlineBackupNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offlineBackupNotifierHash();

  @$internal
  @override
  OfflineBackupNotifier create() => OfflineBackupNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OfflineBackupState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OfflineBackupState>(value),
    );
  }
}

String _$offlineBackupNotifierHash() =>
    r'108b745049c180f93abfaaa3f0e7afa05fc40f32';

abstract class _$OfflineBackupNotifier extends $Notifier<OfflineBackupState> {
  OfflineBackupState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<OfflineBackupState, OfflineBackupState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OfflineBackupState, OfflineBackupState>,
              OfflineBackupState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
