// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_preferences_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CalendarPreferencesNotifier)
final calendarPreferencesNotifierProvider =
    CalendarPreferencesNotifierProvider._();

final class CalendarPreferencesNotifierProvider
    extends
        $AsyncNotifierProvider<
          CalendarPreferencesNotifier,
          CalendarPreferencesState
        > {
  CalendarPreferencesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarPreferencesNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarPreferencesNotifierHash();

  @$internal
  @override
  CalendarPreferencesNotifier create() => CalendarPreferencesNotifier();
}

String _$calendarPreferencesNotifierHash() =>
    r'4e2d63bf5325125d414f5d048deb89f1e31cd9a0';

abstract class _$CalendarPreferencesNotifier
    extends $AsyncNotifier<CalendarPreferencesState> {
  FutureOr<CalendarPreferencesState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<CalendarPreferencesState>,
              CalendarPreferencesState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<CalendarPreferencesState>,
                CalendarPreferencesState
              >,
              AsyncValue<CalendarPreferencesState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
