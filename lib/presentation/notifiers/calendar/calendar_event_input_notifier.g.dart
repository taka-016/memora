// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event_input_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CalendarEventInputNotifier)
final calendarEventInputNotifierProvider = CalendarEventInputNotifierFamily._();

final class CalendarEventInputNotifierProvider
    extends
        $NotifierProvider<CalendarEventInputNotifier, CalendarEventInputState> {
  CalendarEventInputNotifierProvider._({
    required CalendarEventInputNotifierFamily super.from,
    required Object super.argument,
  }) : super(
         retry: null,
         name: r'calendarEventInputNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$calendarEventInputNotifierHash();

  @override
  String toString() {
    return r'calendarEventInputNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CalendarEventInputNotifier create() => CalendarEventInputNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarEventInputState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarEventInputState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CalendarEventInputNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calendarEventInputNotifierHash() =>
    r'a7d6a377366b4ad8d33d69e5c02428ba19d88946';

final class CalendarEventInputNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          CalendarEventInputNotifier,
          CalendarEventInputState,
          CalendarEventInputState,
          CalendarEventInputState,
          Object
        > {
  CalendarEventInputNotifierFamily._()
    : super(
        retry: null,
        name: r'calendarEventInputNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CalendarEventInputNotifierProvider call(Object session) =>
      CalendarEventInputNotifierProvider._(argument: session, from: this);

  @override
  String toString() => r'calendarEventInputNotifierProvider';
}

abstract class _$CalendarEventInputNotifier
    extends $Notifier<CalendarEventInputState> {
  late final _$args = ref.$arg as Object;
  Object get session => _$args;

  CalendarEventInputState build(Object session);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<CalendarEventInputState, CalendarEventInputState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CalendarEventInputState, CalendarEventInputState>,
              CalendarEventInputState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
