// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_notifications_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CalendarNotificationsNotifier)
final calendarNotificationsNotifierProvider =
    CalendarNotificationsNotifierProvider._();

final class CalendarNotificationsNotifierProvider
    extends
        $NotifierProvider<
          CalendarNotificationsNotifier,
          CalendarNotificationsState
        > {
  CalendarNotificationsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarNotificationsNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarNotificationsNotifierHash();

  @$internal
  @override
  CalendarNotificationsNotifier create() => CalendarNotificationsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarNotificationsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarNotificationsState>(value),
    );
  }
}

String _$calendarNotificationsNotifierHash() =>
    r'f09f983ae06d4ceea8b52e2473cfe0636fb1b971';

abstract class _$CalendarNotificationsNotifier
    extends $Notifier<CalendarNotificationsState> {
  CalendarNotificationsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<CalendarNotificationsState, CalendarNotificationsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                CalendarNotificationsState,
                CalendarNotificationsState
              >,
              CalendarNotificationsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
