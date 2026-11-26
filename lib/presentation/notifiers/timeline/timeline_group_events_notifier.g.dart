// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_group_events_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TimelineGroupEventsNotifier)
final timelineGroupEventsNotifierProvider =
    TimelineGroupEventsNotifierFamily._();

final class TimelineGroupEventsNotifierProvider
    extends
        $NotifierProvider<
          TimelineGroupEventsNotifier,
          TimelineGroupEventsState
        > {
  TimelineGroupEventsNotifierProvider._({
    required TimelineGroupEventsNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'timelineGroupEventsNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$timelineGroupEventsNotifierHash();

  @override
  String toString() {
    return r'timelineGroupEventsNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TimelineGroupEventsNotifier create() => TimelineGroupEventsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TimelineGroupEventsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TimelineGroupEventsState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TimelineGroupEventsNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$timelineGroupEventsNotifierHash() =>
    r'5ce039e3a98254a659be9397e1afcc1bccef8a66';

final class TimelineGroupEventsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          TimelineGroupEventsNotifier,
          TimelineGroupEventsState,
          TimelineGroupEventsState,
          TimelineGroupEventsState,
          String
        > {
  TimelineGroupEventsNotifierFamily._()
    : super(
        retry: null,
        name: r'timelineGroupEventsNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TimelineGroupEventsNotifierProvider call(String groupId) =>
      TimelineGroupEventsNotifierProvider._(argument: groupId, from: this);

  @override
  String toString() => r'timelineGroupEventsNotifierProvider';
}

abstract class _$TimelineGroupEventsNotifier
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
