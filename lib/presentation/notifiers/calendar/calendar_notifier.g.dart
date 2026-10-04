// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CalendarNotifier)
final calendarNotifierProvider = CalendarNotifierFamily._();

final class CalendarNotifierProvider
    extends $NotifierProvider<CalendarNotifier, CalendarState> {
  CalendarNotifierProvider._({
    required CalendarNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'calendarNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$calendarNotifierHash();

  @override
  String toString() {
    return r'calendarNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CalendarNotifier create() => CalendarNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CalendarNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calendarNotifierHash() => r'337f1b08fb384c6ae4a5b480ed11aadad13b00ff';

final class CalendarNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          CalendarNotifier,
          CalendarState,
          CalendarState,
          CalendarState,
          String
        > {
  CalendarNotifierFamily._()
    : super(
        retry: null,
        name: r'calendarNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CalendarNotifierProvider call(String groupId) =>
      CalendarNotifierProvider._(argument: groupId, from: this);

  @override
  String toString() => r'calendarNotifierProvider';
}

abstract class _$CalendarNotifier extends $Notifier<CalendarState> {
  late final _$args = ref.$arg as String;
  String get groupId => _$args;

  CalendarState build(String groupId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CalendarState, CalendarState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CalendarState, CalendarState>,
              CalendarState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
