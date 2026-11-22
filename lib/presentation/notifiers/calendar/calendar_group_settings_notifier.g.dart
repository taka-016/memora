// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_group_settings_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CalendarGroupSettingsNotifier)
final calendarGroupSettingsNotifierProvider =
    CalendarGroupSettingsNotifierProvider._();

final class CalendarGroupSettingsNotifierProvider
    extends
        $NotifierProvider<
          CalendarGroupSettingsNotifier,
          CalendarGroupSettingsState
        > {
  CalendarGroupSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarGroupSettingsNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarGroupSettingsNotifierHash();

  @$internal
  @override
  CalendarGroupSettingsNotifier create() => CalendarGroupSettingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarGroupSettingsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarGroupSettingsState>(value),
    );
  }
}

String _$calendarGroupSettingsNotifierHash() =>
    r'3e08630947b7f25c579a151b625475892db8f12d';

abstract class _$CalendarGroupSettingsNotifier
    extends $Notifier<CalendarGroupSettingsState> {
  CalendarGroupSettingsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<CalendarGroupSettingsState, CalendarGroupSettingsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                CalendarGroupSettingsState,
                CalendarGroupSettingsState
              >,
              CalendarGroupSettingsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
