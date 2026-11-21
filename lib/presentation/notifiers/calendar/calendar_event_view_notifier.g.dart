// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event_view_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CalendarEventViewNotifier)
final calendarEventViewNotifierProvider = CalendarEventViewNotifierFamily._();

final class CalendarEventViewNotifierProvider
    extends
        $NotifierProvider<CalendarEventViewNotifier, CalendarEventViewState> {
  CalendarEventViewNotifierProvider._({
    required CalendarEventViewNotifierFamily super.from,
    required (Object, CalendarEventDto, {CalendarEventDto? series})
    super.argument,
  }) : super(
         retry: null,
         name: r'calendarEventViewNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$calendarEventViewNotifierHash();

  @override
  String toString() {
    return r'calendarEventViewNotifierProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  CalendarEventViewNotifier create() => CalendarEventViewNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarEventViewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarEventViewState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CalendarEventViewNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calendarEventViewNotifierHash() =>
    r'f6b09c169d3061ac5cf04a069a177dfd2cb79a3d';

final class CalendarEventViewNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          CalendarEventViewNotifier,
          CalendarEventViewState,
          CalendarEventViewState,
          CalendarEventViewState,
          (Object, CalendarEventDto, {CalendarEventDto? series})
        > {
  CalendarEventViewNotifierFamily._()
    : super(
        retry: null,
        name: r'calendarEventViewNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CalendarEventViewNotifierProvider call(
    Object session,
    CalendarEventDto event, {
    CalendarEventDto? series,
  }) => CalendarEventViewNotifierProvider._(
    argument: (session, event, series: series),
    from: this,
  );

  @override
  String toString() => r'calendarEventViewNotifierProvider';
}

abstract class _$CalendarEventViewNotifier
    extends $Notifier<CalendarEventViewState> {
  late final _$args =
      ref.$arg as (Object, CalendarEventDto, {CalendarEventDto? series});
  Object get session => _$args.$1;
  CalendarEventDto get event => _$args.$2;
  CalendarEventDto? get series => _$args.series;

  CalendarEventViewState build(
    Object session,
    CalendarEventDto event, {
    CalendarEventDto? series,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<CalendarEventViewState, CalendarEventViewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CalendarEventViewState, CalendarEventViewState>,
              CalendarEventViewState,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(_$args.$1, _$args.$2, series: _$args.series),
    );
  }
}
