// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_labels_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CalendarLabelsNotifier)
final calendarLabelsNotifierProvider = CalendarLabelsNotifierFamily._();

final class CalendarLabelsNotifierProvider
    extends $NotifierProvider<CalendarLabelsNotifier, CalendarLabelsState> {
  CalendarLabelsNotifierProvider._({
    required CalendarLabelsNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'calendarLabelsNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$calendarLabelsNotifierHash();

  @override
  String toString() {
    return r'calendarLabelsNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CalendarLabelsNotifier create() => CalendarLabelsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarLabelsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarLabelsState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CalendarLabelsNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calendarLabelsNotifierHash() =>
    r'dcdfa7393a0b86eebbcb1bfbf756bcd27597cf39';

final class CalendarLabelsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          CalendarLabelsNotifier,
          CalendarLabelsState,
          CalendarLabelsState,
          CalendarLabelsState,
          String
        > {
  CalendarLabelsNotifierFamily._()
    : super(
        retry: null,
        name: r'calendarLabelsNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CalendarLabelsNotifierProvider call(String groupId) =>
      CalendarLabelsNotifierProvider._(argument: groupId, from: this);

  @override
  String toString() => r'calendarLabelsNotifierProvider';
}

abstract class _$CalendarLabelsNotifier extends $Notifier<CalendarLabelsState> {
  late final _$args = ref.$arg as String;
  String get groupId => _$args;

  CalendarLabelsState build(String groupId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CalendarLabelsState, CalendarLabelsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CalendarLabelsState, CalendarLabelsState>,
              CalendarLabelsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
