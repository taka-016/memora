// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_notification_preferences_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CalendarNotificationPreferencesNotifier)
final calendarNotificationPreferencesNotifierProvider =
    CalendarNotificationPreferencesNotifierProvider._();

final class CalendarNotificationPreferencesNotifierProvider
    extends
        $AsyncNotifierProvider<
          CalendarNotificationPreferencesNotifier,
          CalendarNotificationPreferencesState
        > {
  CalendarNotificationPreferencesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarNotificationPreferencesNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$calendarNotificationPreferencesNotifierHash();

  @$internal
  @override
  CalendarNotificationPreferencesNotifier create() =>
      CalendarNotificationPreferencesNotifier();
}

String _$calendarNotificationPreferencesNotifierHash() =>
    r'd7ac779927e00a7af6a324ab097eb44bcc3a9e96';

abstract class _$CalendarNotificationPreferencesNotifier
    extends $AsyncNotifier<CalendarNotificationPreferencesState> {
  FutureOr<CalendarNotificationPreferencesState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<CalendarNotificationPreferencesState>,
              CalendarNotificationPreferencesState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<CalendarNotificationPreferencesState>,
                CalendarNotificationPreferencesState
              >,
              AsyncValue<CalendarNotificationPreferencesState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
