// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_display_settings_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CalendarDisplaySettingsNotifier)
final calendarDisplaySettingsNotifierProvider =
    CalendarDisplaySettingsNotifierProvider._();

final class CalendarDisplaySettingsNotifierProvider
    extends
        $AsyncNotifierProvider<
          CalendarDisplaySettingsNotifier,
          CalendarDisplaySettingsState
        > {
  CalendarDisplaySettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'calendarDisplaySettingsNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarDisplaySettingsNotifierHash();

  @$internal
  @override
  CalendarDisplaySettingsNotifier create() => CalendarDisplaySettingsNotifier();
}

String _$calendarDisplaySettingsNotifierHash() =>
    r'4c5c4bed6b70da226ed6900bb3cadc4846c2d0c3';

abstract class _$CalendarDisplaySettingsNotifier
    extends $AsyncNotifier<CalendarDisplaySettingsState> {
  FutureOr<CalendarDisplaySettingsState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<CalendarDisplaySettingsState>,
              CalendarDisplaySettingsState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<CalendarDisplaySettingsState>,
                CalendarDisplaySettingsState
              >,
              AsyncValue<CalendarDisplaySettingsState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
