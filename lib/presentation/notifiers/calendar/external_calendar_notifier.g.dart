// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'external_calendar_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExternalCalendarNotifier)
final externalCalendarNotifierProvider = ExternalCalendarNotifierProvider._();

final class ExternalCalendarNotifierProvider
    extends $NotifierProvider<ExternalCalendarNotifier, ExternalCalendarState> {
  ExternalCalendarNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'externalCalendarNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$externalCalendarNotifierHash();

  @$internal
  @override
  ExternalCalendarNotifier create() => ExternalCalendarNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExternalCalendarState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExternalCalendarState>(value),
    );
  }
}

String _$externalCalendarNotifierHash() =>
    r'fab422529b81cb01c08b872cb596c3a3d7efa2f6';

abstract class _$ExternalCalendarNotifier
    extends $Notifier<ExternalCalendarState> {
  ExternalCalendarState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ExternalCalendarState, ExternalCalendarState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExternalCalendarState, ExternalCalendarState>,
              ExternalCalendarState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
