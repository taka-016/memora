import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_mapper.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_member_mapper.dart';

class FirestoreGroupQueryService implements GroupQueryService {
  final FirebaseFirestore _firestore;

  FirestoreGroupQueryService({FirebaseFirestore? firestore, this._options})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final GetOptions? _options;

  @override
  Future<bool> groupExists(String groupId) async =>
      (await _firestore.collection('groups').doc(groupId).get(_options)).exists;

  Future<bool> isGroupMember(String groupId, String memberId) async =>
      (await _firestore
              .collection('group_members')
              .doc('$groupId:$memberId')
              .get(_options))
          .exists;

  @override
  Future<Set<String>> getGroupIdsByMemberId(String memberId) async {
    final memberships = await _membershipsForMember(memberId);
    final groupIds = <String>{};
    for (final membership in memberships.docs) {
      final groupId = membership.data()['groupId'] as String;
      if (await groupExists(groupId)) groupIds.add(groupId);
    }
    return groupIds;
  }

  @override
  Future<List<GroupDto>> getGroupsWithMembersByMemberId(
    String memberId, {
    List<OrderBy>? groupsOrderBy,
    List<OrderBy>? membersOrderBy,
  }) async {
    try {
      final allGroups = await _groupsForMember(memberId, managed: false);
      final sortedGroups = _sortGroups(allGroups, groupsOrderBy);

      return await _addMembersToGroups(
        sortedGroups,
        membersOrderBy: membersOrderBy,
      );
    } catch (e, stack) {
      if (e is FirebaseException && e.code == 'permission-denied') rethrow;
      logger.e(
        'FirestoreGroupQueryService.getGroupsWithMembersByMemberId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<List<GroupDto>> getManagedGroupsWithMembersByOwnerId(
    String ownerId, {
    List<OrderBy>? groupsOrderBy,
    List<OrderBy>? membersOrderBy,
  }) async {
    try {
      final managedGroups = _sortGroups(
        await _groupsForMember(ownerId, managed: true),
        groupsOrderBy,
      );
      return await _addMembersToGroups(
        managedGroups,
        membersOrderBy: membersOrderBy,
      );
    } catch (e, stack) {
      if (e is FirebaseException && e.code == 'permission-denied') rethrow;
      logger.e(
        'FirestoreGroupQueryService.getManagedGroupsWithMembersByOwnerId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<GroupDto?> getGroupWithMembersById(
    String groupId, {
    List<OrderBy>? membersOrderBy,
  }) async {
    try {
      final groupSnapshot = await _firestore
          .collection('groups')
          .doc(groupId)
          .get(_options);

      if (!groupSnapshot.exists) {
        return null;
      }

      final members = await _getMembersForGroup(
        groupId,
        orderBy: membersOrderBy,
      );
      return FirestoreGroupMapper.fromFirestore(
        groupSnapshot,
        members: members,
      );
    } catch (e, stack) {
      if (e is FirebaseException && e.code == 'permission-denied') rethrow;
      logger.e(
        'FirestoreGroupQueryService.getGroupWithMembersById: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<List<GroupDto>> _groupsForMember(
    String memberId, {
    required bool managed,
  }) async {
    final memberships = await _membershipsForMember(memberId);
    final groups = <GroupDto>[];
    for (final membership in memberships.docs) {
      final data = membership.data();
      final id = data['groupId'] as String;
      final doc = await _firestore.collection('groups').doc(id).get(_options);
      if (!doc.exists) continue;
      final group = FirestoreGroupMapper.fromFirestore(doc);
      if (!managed ||
          group.ownerId == memberId ||
          data['isAdministrator'] == true) {
        groups.add(group);
      }
    }
    return groups;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _membershipsForMember(
    String memberId,
  ) => _firestore
      .collection('group_members')
      .where('memberId', isEqualTo: memberId)
      .get(_options);

  List<GroupDto> _sortGroups(List<GroupDto> groups, List<OrderBy>? orderBy) {
    if (orderBy == null || orderBy.isEmpty) {
      return groups;
    }

    final sortedGroups = List<GroupDto>.from(groups);
    sortedGroups.sort((a, b) {
      for (final order in orderBy) {
        int comparison = 0;
        if (order.field == 'name') {
          comparison = a.name.compareTo(b.name);
        }
        if (comparison != 0) {
          return order.descending ? -comparison : comparison;
        }
      }
      return 0;
    });

    return sortedGroups;
  }

  Future<List<GroupDto>> _addMembersToGroups(
    List<GroupDto> groups, {
    List<OrderBy>? membersOrderBy,
  }) async {
    final List<GroupDto> result = [];

    for (final group in groups) {
      final members = await _getMembersForGroup(
        group.id,
        orderBy: membersOrderBy,
      );
      result.add(group.copyWith(members: members, originalMembers: members));
    }

    return result;
  }

  Future<List<GroupMemberDto>> _getMembersForGroup(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    final groupMembersSnapshot = await _firestore
        .collection('group_members')
        .where('groupId', isEqualTo: groupId)
        .get(_options);

    final List<GroupMemberDto> members = [];

    for (final doc in groupMembersSnapshot.docs) {
      final memberId = doc.data()['memberId'] as String;
      final memberSnapshot = await _firestore
          .collection('members')
          .doc(memberId)
          .get(_options);

      if (memberSnapshot.exists) {
        members.add(
          FirestoreGroupMemberMapper.fromFirestore(doc, memberSnapshot),
        );
      }
    }

    return _sortMembers(members, orderBy);
  }

  List<GroupMemberDto> _sortMembers(
    List<GroupMemberDto> members,
    List<OrderBy>? orderBy,
  ) {
    if (orderBy == null || orderBy.isEmpty) {
      return members;
    }

    final sortedMembers = List<GroupMemberDto>.from(members);
    sortedMembers.sort((a, b) {
      for (final order in orderBy) {
        int comparison = 0;
        if (order.field == 'orderIndex') {
          comparison = a.orderIndex.compareTo(b.orderIndex);
        }
        if (comparison != 0) {
          return order.descending ? -comparison : comparison;
        }
      }
      return 0;
    });

    return sortedMembers;
  }
}
