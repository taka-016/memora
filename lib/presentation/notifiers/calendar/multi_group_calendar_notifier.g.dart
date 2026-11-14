// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multi_group_calendar_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MultiGroupCalendarNotifier)
final multiGroupCalendarNotifierProvider =
    MultiGroupCalendarNotifierProvider._();

final class MultiGroupCalendarNotifierProvider
    extends
        $NotifierProvider<MultiGroupCalendarNotifier, MultiGroupCalendarState> {
  MultiGroupCalendarNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'multiGroupCalendarNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$multiGroupCalendarNotifierHash();

  @$internal
  @override
  MultiGroupCalendarNotifier create() => MultiGroupCalendarNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MultiGroupCalendarState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MultiGroupCalendarState>(value),
    );
  }
}

String _$multiGroupCalendarNotifierHash() =>
    r'0a3af2cf6ef1289cf5ca8241f2a93940027cb071';

abstract class _$MultiGroupCalendarNotifier
    extends $Notifier<MultiGroupCalendarState> {
  MultiGroupCalendarState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<MultiGroupCalendarState, MultiGroupCalendarState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MultiGroupCalendarState, MultiGroupCalendarState>,
              MultiGroupCalendarState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
