// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_group_events_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TimelineGroupEvents)
final timelineGroupEventsProvider = TimelineGroupEventsFamily._();

final class TimelineGroupEventsProvider
    extends $NotifierProvider<TimelineGroupEvents, TimelineGroupEventsState> {
  TimelineGroupEventsProvider._({
    required TimelineGroupEventsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'timelineGroupEventsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$timelineGroupEventsHash();

  @override
  String toString() {
    return r'timelineGroupEventsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TimelineGroupEvents create() => TimelineGroupEvents();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TimelineGroupEventsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TimelineGroupEventsState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TimelineGroupEventsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$timelineGroupEventsHash() =>
    r'91e02a4344f62662087de561b0f1758eb5668894';

final class TimelineGroupEventsFamily extends $Family
    with
        $ClassFamilyOverride<
          TimelineGroupEvents,
          TimelineGroupEventsState,
          TimelineGroupEventsState,
          TimelineGroupEventsState,
          String
        > {
  TimelineGroupEventsFamily._()
    : super(
        retry: null,
        name: r'timelineGroupEventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TimelineGroupEventsProvider call(String groupId) =>
      TimelineGroupEventsProvider._(argument: groupId, from: this);

  @override
  String toString() => r'timelineGroupEventsProvider';
}

abstract class _$TimelineGroupEvents
    extends $Notifier<TimelineGroupEventsState> {
  late final _$args = ref.$arg as String;
  String get groupId => _$args;

  TimelineGroupEventsState build(String groupId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<TimelineGroupEventsState, TimelineGroupEventsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TimelineGroupEventsState, TimelineGroupEventsState>,
              TimelineGroupEventsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
