import 'package:memora/domain/entities/calendar/calendar_event.dart';
import 'package:memora/domain/entities/calendar/calendar_label.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';
import 'package:memora/domain/entities/group/group.dart';
import 'package:memora/domain/entities/group/group_event.dart';
import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/domain/entities/member/member_event.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/domain/repositories/calendar/calendar_event_repository.dart';
import 'package:memora/domain/repositories/calendar/calendar_label_repository.dart';
import 'package:memora/domain/repositories/dvc/dvc_limited_point_repository.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_contract_repository.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_usage_repository.dart';
import 'package:memora/domain/repositories/group/group_event_repository.dart';
import 'package:memora/domain/repositories/group/group_repository.dart';
import 'package:memora/domain/repositories/member/member_event_repository.dart';
import 'package:memora/domain/repositories/member/member_invitation_repository.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';

T guardRepository<T extends Object>(
  T repository,
  Future<void> Function() ensureAvailable,
) {
  if (T == CalendarEventRepository) {
    return GuardedCalendarEventRepository(
      repository as CalendarEventRepository,
      ensureAvailable,
    ) as T;
  }
  if (T == CalendarLabelRepository) {
    return GuardedCalendarLabelRepository(
      repository as CalendarLabelRepository,
      ensureAvailable,
    ) as T;
  }
  if (T == DvcLimitedPointRepository) {
    return GuardedDvcLimitedPointRepository(
      repository as DvcLimitedPointRepository,
      ensureAvailable,
    ) as T;
  }
  if (T == DvcPointContractRepository) {
    return GuardedDvcPointContractRepository(
      repository as DvcPointContractRepository,
      ensureAvailable,
    ) as T;
  }
  if (T == DvcPointUsageRepository) {
    return GuardedDvcPointUsageRepository(
      repository as DvcPointUsageRepository,
      ensureAvailable,
    ) as T;
  }
  if (T == GroupEventRepository) {
    return GuardedGroupEventRepository(
      repository as GroupEventRepository,
      ensureAvailable,
    ) as T;
  }
  if (T == GroupRepository) {
    return GuardedGroupRepository(
      repository as GroupRepository,
      ensureAvailable,
    ) as T;
  }
  if (T == MemberEventRepository) {
    return GuardedMemberEventRepository(
      repository as MemberEventRepository,
      ensureAvailable,
    ) as T;
  }
  if (T == MemberInvitationRepository) {
    return GuardedMemberInvitationRepository(
      repository as MemberInvitationRepository,
      ensureAvailable,
    ) as T;
  }
  if (T == MemberRepository) {
    return GuardedMemberRepository(
      repository as MemberRepository,
      ensureAvailable,
    ) as T;
  }
  if (T == TripEntryRepository) {
    return GuardedTripEntryRepository(
      repository as TripEntryRepository,
      ensureAvailable,
    ) as T;
  }
  throw ArgumentError('未対応のRepositoryです: $T');
}

class GuardedCalendarEventRepository implements CalendarEventRepository {
  const GuardedCalendarEventRepository(this._delegate, this._ensureAvailable);

  final CalendarEventRepository _delegate;
  final Future<void> Function() _ensureAvailable;

  @override
  Future<void> moveCalendarEvent(
    CalendarEvent expected,
    CalendarEvent replacement,
  ) async {
    await _ensureAvailable();
    return await _delegate.moveCalendarEvent(expected, replacement);
  }

  @override
  Future<void> replaceCalendarEvent(
    CalendarEvent expected,
    CalendarEvent? replacement,
    CalendarEvent? following, {
    List<CalendarEvent> preservedEvents = const [],
  }) async {
    await _ensureAvailable();
    return await _delegate.replaceCalendarEvent(
      expected,
      replacement,
      following,
      preservedEvents: preservedEvents,
    );
  }

  @override
  Future<String> saveCalendarEvent(CalendarEvent event) async {
    await _ensureAvailable();
    return await _delegate.saveCalendarEvent(event);
  }

  @override
  Future<void> updateCalendarEvent(CalendarEvent event) async {
    await _ensureAvailable();
    return await _delegate.updateCalendarEvent(event);
  }

  @override
  Future<void> deleteCalendarEvent(
    String eventId, {
    int? expectedVersion,
  }) async {
    await _ensureAvailable();
    return await _delegate.deleteCalendarEvent(
      eventId,
      expectedVersion: expectedVersion,
    );
  }
}

class GuardedCalendarLabelRepository implements CalendarLabelRepository {
  const GuardedCalendarLabelRepository(this._delegate, this._ensureAvailable);

  final CalendarLabelRepository _delegate;
  final Future<void> Function() _ensureAvailable;

  @override
  Future<String> saveCalendarLabel(CalendarLabel label) async {
    await _ensureAvailable();
    return await _delegate.saveCalendarLabel(label);
  }

  @override
  Future<void> deleteCalendarLabel(
    String labelId, {
    int? expectedVersion,
  }) async {
    await _ensureAvailable();
    return await _delegate.deleteCalendarLabel(
      labelId,
      expectedVersion: expectedVersion,
    );
  }

  @override
  Future<void> reorderCalendarLabels(
    String groupId,
    List<String> labelIds, {
    Map<String, int> expectedVersions = const {},
  }) async {
    await _ensureAvailable();
    return await _delegate.reorderCalendarLabels(
      groupId,
      labelIds,
      expectedVersions: expectedVersions,
    );
  }
}

class GuardedDvcLimitedPointRepository implements DvcLimitedPointRepository {
  const GuardedDvcLimitedPointRepository(this._delegate, this._ensureAvailable);

  final DvcLimitedPointRepository _delegate;
  final Future<void> Function() _ensureAvailable;

  @override
  Future<void> saveDvcLimitedPoint(
    DvcLimitedPoint limitedPoint, {
    int? expectedContractVersion,
  }) async {
    await _ensureAvailable();
    return await _delegate.saveDvcLimitedPoint(
      limitedPoint,
      expectedContractVersion: expectedContractVersion,
    );
  }

  @override
  Future<void> deleteDvcLimitedPoint(
    String limitedPointId, {
    int? expectedContractVersion,
  }) async {
    await _ensureAvailable();
    return await _delegate.deleteDvcLimitedPoint(
      limitedPointId,
      expectedContractVersion: expectedContractVersion,
    );
  }

  @override
  Future<void> deleteDvcLimitedPointsByGroupId(String groupId) async {
    await _ensureAvailable();
    return await _delegate.deleteDvcLimitedPointsByGroupId(groupId);
  }
}

class GuardedDvcPointContractRepository implements DvcPointContractRepository {
  const GuardedDvcPointContractRepository(
    this._delegate,
    this._ensureAvailable,
  );

  final DvcPointContractRepository _delegate;
  final Future<void> Function() _ensureAvailable;

  @override
  Future<void> saveDvcPointContracts(
    String groupId,
    List<DvcPointContract> contracts, {
    Map<String, int> expectedVersions = const {},
    List<DvcPointContract> originalContracts = const [],
  }) async {
    await _ensureAvailable();
    return await _delegate.saveDvcPointContracts(
      groupId,
      contracts,
      expectedVersions: expectedVersions,
      originalContracts: originalContracts,
    );
  }

  @override
  Future<void> saveDvcPointContract(DvcPointContract contract) async {
    await _ensureAvailable();
    return await _delegate.saveDvcPointContract(contract);
  }

  @override
  Future<void> deleteDvcPointContract(
    String contractId, {
    int? expectedVersion,
  }) async {
    await _ensureAvailable();
    return await _delegate.deleteDvcPointContract(
      contractId,
      expectedVersion: expectedVersion,
    );
  }

  @override
  Future<void> deleteDvcPointContractsByGroupId(String groupId) async {
    await _ensureAvailable();
    return await _delegate.deleteDvcPointContractsByGroupId(groupId);
  }
}

class GuardedDvcPointUsageRepository implements DvcPointUsageRepository {
  const GuardedDvcPointUsageRepository(this._delegate, this._ensureAvailable);

  final DvcPointUsageRepository _delegate;
  final Future<void> Function() _ensureAvailable;

  @override
  Future<void> saveDvcPointUsage(
    DvcPointUsage pointUsage, {
    int? expectedContractVersion,
  }) async {
    await _ensureAvailable();
    return await _delegate.saveDvcPointUsage(
      pointUsage,
      expectedContractVersion: expectedContractVersion,
    );
  }

  @override
  Future<void> deleteDvcPointUsage(
    String pointUsageId, {
    int? expectedContractVersion,
  }) async {
    await _ensureAvailable();
    return await _delegate.deleteDvcPointUsage(
      pointUsageId,
      expectedContractVersion: expectedContractVersion,
    );
  }

  @override
  Future<void> deleteDvcPointUsagesByGroupId(String groupId) async {
    await _ensureAvailable();
    return await _delegate.deleteDvcPointUsagesByGroupId(groupId);
  }
}

class GuardedGroupEventRepository implements GroupEventRepository {
  const GuardedGroupEventRepository(this._delegate, this._ensureAvailable);

  final GroupEventRepository _delegate;
  final Future<void> Function() _ensureAvailable;

  @override
  Future<String> saveGroupEvent(GroupEvent groupEvent) async {
    await _ensureAvailable();
    return await _delegate.saveGroupEvent(groupEvent);
  }

  @override
  Future<void> deleteGroupEvent(
    String groupEventId, {
    int? expectedVersion,
  }) async {
    await _ensureAvailable();
    return await _delegate.deleteGroupEvent(
      groupEventId,
      expectedVersion: expectedVersion,
    );
  }

  @override
  Future<void> deleteGroupEventsByGroupId(String groupId) async {
    await _ensureAvailable();
    return await _delegate.deleteGroupEventsByGroupId(groupId);
  }
}

class GuardedGroupRepository implements GroupRepository {
  const GuardedGroupRepository(this._delegate, this._ensureAvailable);

  final GroupRepository _delegate;
  final Future<void> Function() _ensureAvailable;

  @override
  Future<String> saveGroup(Group group) async {
    await _ensureAvailable();
    return await _delegate.saveGroup(group);
  }

  @override
  Future<void> updateGroup(Group group) async {
    await _ensureAvailable();
    return await _delegate.updateGroup(group);
  }

  @override
  Future<void> deleteGroup(String groupId, {int? expectedVersion}) async {
    await _ensureAvailable();
    return await _delegate.deleteGroup(
      groupId,
      expectedVersion: expectedVersion,
    );
  }

  @override
  Future<void> deleteGroupMembersByMemberId(String memberId) async {
    await _ensureAvailable();
    return await _delegate.deleteGroupMembersByMemberId(memberId);
  }
}

class GuardedMemberEventRepository implements MemberEventRepository {
  const GuardedMemberEventRepository(this._delegate, this._ensureAvailable);

  final MemberEventRepository _delegate;
  final Future<void> Function() _ensureAvailable;

  @override
  Future<String> saveMemberEvent(MemberEvent memberEvent) async {
    await _ensureAvailable();
    return await _delegate.saveMemberEvent(memberEvent);
  }

  @override
  Future<void> deleteMemberEvent(
    String memberEventId, {
    int? expectedVersion,
  }) async {
    await _ensureAvailable();
    return await _delegate.deleteMemberEvent(
      memberEventId,
      expectedVersion: expectedVersion,
    );
  }

  @override
  Future<void> deleteMemberEventsByMemberId(String memberId) async {
    await _ensureAvailable();
    return await _delegate.deleteMemberEventsByMemberId(memberId);
  }
}

class GuardedMemberInvitationRepository implements MemberInvitationRepository {
  const GuardedMemberInvitationRepository(
    this._delegate,
    this._ensureAvailable,
  );

  final MemberInvitationRepository _delegate;
  final Future<void> Function() _ensureAvailable;

  @override
  Future<void> acceptInvitation(
    Member member,
    List<MemberInvitation> invitations,
  ) async {
    await _ensureAvailable();
    return await _delegate.acceptInvitation(member, invitations);
  }

  @override
  Future<void> saveMemberInvitation(MemberInvitation memberInvitation) async {
    await _ensureAvailable();
    return await _delegate.saveMemberInvitation(memberInvitation);
  }

  @override
  Future<void> updateMemberInvitation(MemberInvitation memberInvitation) async {
    await _ensureAvailable();
    return await _delegate.updateMemberInvitation(memberInvitation);
  }

  @override
  Future<void> deleteMemberInvitation(String id, {int? expectedVersion}) async {
    await _ensureAvailable();
    return await _delegate.deleteMemberInvitation(
      id,
      expectedVersion: expectedVersion,
    );
  }
}

class GuardedMemberRepository implements MemberRepository {
  const GuardedMemberRepository(this._delegate, this._ensureAvailable);

  final MemberRepository _delegate;
  final Future<void> Function() _ensureAvailable;

  @override
  Future<void> saveMember(Member member) async {
    await _ensureAvailable();
    return await _delegate.saveMember(member);
  }

  @override
  Future<void> updateMember(Member member) async {
    await _ensureAvailable();
    return await _delegate.updateMember(member);
  }

  @override
  Future<void> deleteMember(String memberId, {int? expectedVersion}) async {
    await _ensureAvailable();
    return await _delegate.deleteMember(
      memberId,
      expectedVersion: expectedVersion,
    );
  }
}

class GuardedTripEntryRepository implements TripEntryRepository {
  const GuardedTripEntryRepository(this._delegate, this._ensureAvailable);

  final TripEntryRepository _delegate;
  final Future<void> Function() _ensureAvailable;

  @override
  Future<String> saveTripEntry(TripEntry tripEntry) async {
    await _ensureAvailable();
    return await _delegate.saveTripEntry(tripEntry);
  }

  @override
  Future<void> updateTripEntry(TripEntry tripEntry) async {
    await _ensureAvailable();
    return await _delegate.updateTripEntry(tripEntry);
  }

  @override
  Future<void> deleteTripEntry(String tripId, {int? expectedVersion}) async {
    await _ensureAvailable();
    return await _delegate.deleteTripEntry(
      tripId,
      expectedVersion: expectedVersion,
    );
  }

  @override
  Future<void> deleteTripEntriesByGroupId(String groupId) async {
    await _ensureAvailable();
    return await _delegate.deleteTripEntriesByGroupId(groupId);
  }
}
