// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_member_events_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(timelineMemberEventsByYear)
final timelineMemberEventsByYearProvider = TimelineMemberEventsByYearFamily._();

final class TimelineMemberEventsByYearProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<int, MemberEventDto>>,
          Map<int, MemberEventDto>,
          FutureOr<Map<int, MemberEventDto>>
        >
    with
        $FutureModifier<Map<int, MemberEventDto>>,
        $FutureProvider<Map<int, MemberEventDto>> {
  TimelineMemberEventsByYearProvider._({
    required TimelineMemberEventsByYearFamily super.from,
    required ({String groupId, String memberId}) super.argument,
  }) : super(
         retry: _noRetry,
         name: r'timelineMemberEventsByYearProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$timelineMemberEventsByYearHash();

  @override
  String toString() {
    return r'timelineMemberEventsByYearProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<Map<int, MemberEventDto>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<int, MemberEventDto>> create(Ref ref) {
    final argument = this.argument as ({String groupId, String memberId});
    return timelineMemberEventsByYear(
      ref,
      groupId: argument.groupId,
      memberId: argument.memberId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TimelineMemberEventsByYearProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$timelineMemberEventsByYearHash() =>
    r'4d28ca7651c6525ce2ba3127a3d2bbb403aef843';

final class TimelineMemberEventsByYearFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<Map<int, MemberEventDto>>,
          ({String groupId, String memberId})
        > {
  TimelineMemberEventsByYearFamily._()
    : super(
        retry: _noRetry,
        name: r'timelineMemberEventsByYearProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TimelineMemberEventsByYearProvider call({
    required String groupId,
    required String memberId,
  }) => TimelineMemberEventsByYearProvider._(
    argument: (groupId: groupId, memberId: memberId),
    from: this,
  );

  @override
  String toString() => r'timelineMemberEventsByYearProvider';
}
