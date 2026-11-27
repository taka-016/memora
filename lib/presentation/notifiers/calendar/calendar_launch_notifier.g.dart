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
    r'4e524ecbbeea71f4c84eaab36ff240ca917dc41e';

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
