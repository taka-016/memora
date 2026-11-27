// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_launch_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CalendarLaunchNotifier)
final calendarLaunchNotifierProvider = CalendarLaunchNotifierProvider._();

final class CalendarLaunchNotifierProvider
    extends $NotifierProvider<CalendarLaunchNotifier, CalendarLaunchState> {
  CalendarLaunchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarLaunchNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarLaunchNotifierHash();

  @$internal
  @override
  CalendarLaunchNotifier create() => CalendarLaunchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarLaunchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarLaunchState>(value),
    );
  }
}

String _$calendarLaunchNotifierHash() =>
    r'721c5b2872374b85e92b0633bdc3a72f2a77024c';

abstract class _$CalendarLaunchNotifier extends $Notifier<CalendarLaunchState> {
  CalendarLaunchState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CalendarLaunchState, CalendarLaunchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CalendarLaunchState, CalendarLaunchState>,
              CalendarLaunchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
