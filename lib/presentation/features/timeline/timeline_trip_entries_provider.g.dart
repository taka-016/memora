// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_trip_entries_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(timelineTripEntries)
final timelineTripEntriesProvider = TimelineTripEntriesFamily._();

final class TimelineTripEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TripEntryDto>>,
          List<TripEntryDto>,
          FutureOr<List<TripEntryDto>>
        >
    with
        $FutureModifier<List<TripEntryDto>>,
        $FutureProvider<List<TripEntryDto>> {
  TimelineTripEntriesProvider._({
    required TimelineTripEntriesFamily super.from,
    required ({String groupId, int year}) super.argument,
  }) : super(
         retry: _disableRetry,
         name: r'timelineTripEntriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$timelineTripEntriesHash();

  @override
  String toString() {
    return r'timelineTripEntriesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<TripEntryDto>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TripEntryDto>> create(Ref ref) {
    final argument = this.argument as ({String groupId, int year});
    return timelineTripEntries(
      ref,
      groupId: argument.groupId,
      year: argument.year,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TimelineTripEntriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$timelineTripEntriesHash() =>
    r'd90d73bb851fac2312b940f5d9ce14f158b9e13b';

final class TimelineTripEntriesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<TripEntryDto>>,
          ({String groupId, int year})
        > {
  TimelineTripEntriesFamily._()
    : super(
        retry: _disableRetry,
        name: r'timelineTripEntriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TimelineTripEntriesProvider call({
    required String groupId,
    required int year,
  }) => TimelineTripEntriesProvider._(
    argument: (groupId: groupId, year: year),
    from: this,
  );

  @override
  String toString() => r'timelineTripEntriesProvider';
}
