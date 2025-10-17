import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/interfaces/group_query_service.dart';
import 'package:memora/application/dtos/group/group_with_members_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/mappers/member_mapper.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/domain/value_objects/order_by.dart';

class FirestoreGroupQueryService implements GroupQueryService {
  final FirebaseFirestore _firestore;

  FirestoreGroupQueryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<GroupWithMembersDto>> getGroupsWithMembersByMemberId(
    String memberId, {
    List<OrderBy>? groupsOrderBy,
    List<OrderBy>? membersOrderBy,
  }) async {
    try {
      final adminGroups = await _getGroupsWhereUserIsOwner(memberId);
      final memberGroups = await _getGroupsWhereUserIsMember(memberId);
      final allGroups = _mergeUniqueGroups(adminGroups, memberGroups);
      final sortedGroups = _sortGroups(allGroups, groupsOrderBy);

      return await _addMembersToGroups(
        sortedGroups,
        membersOrderBy: membersOrderBy,
      );
    } catch (e, stack) {
      logger.e(
        'FirestoreGroupQueryService.getGroupsWithMembersByMemberId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<List<GroupWithMembersDto>> getManagedGroupsWithMembersByOwnerId(
    String ownerId, {
    List<OrderBy>? groupsOrderBy,
    List<OrderBy>? membersOrderBy,
  }) async {
    try {
      final managedGroups = await _getGroupsWhereUserIsOwner(
        ownerId,
        orderBy: groupsOrderBy,
      );
      return await _addMembersToGroups(
        managedGroups,
        membersOrderBy: membersOrderBy,
      );
    } catch (e, stack) {
      logger.e(
        'FirestoreGroupQueryService.getManagedGroupsWithMembersByOwnerId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<GroupWithMembersDto?> getGroupWithMembersById(
    String groupId, {
    List<OrderBy>? membersOrderBy,
  }) async {
    try {
      final groupSnapshot = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();

      if (!groupSnapshot.exists) {
        return null;
      }

      final groupData = groupSnapshot.data()!;
      final members = await _getMembersForGroup(
        groupId,
        orderBy: membersOrderBy,
      );

      return GroupWithMembersDto(
        groupId: groupId,
        groupName: groupData['name'] as String,
        members: members,
      );
    } catch (e, stack) {
      logger.e(
        'FirestoreGroupQueryService.getGroupWithMembersById: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  Future<List<GroupWithMembersDto>> _getGroupsWhereUserIsOwner(
    String memberId, {
    List<OrderBy>? orderBy,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('groups')
        .where('ownerId', isEqualTo: memberId);

    if (orderBy != null) {
      for (final order in orderBy) {
        query = query.orderBy(order.field, descending: order.descending);
      }
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return GroupWithMembersDto(
        id: doc.id,
        name: data['name'] as String,
        members: [],
      );
    }).toList();
  }

  Future<List<GroupWithMembersDto>> _getGroupsWhereUserIsMember(
    String memberId,
  ) async {
    final groupMembersSnapshot = await _firestore
        .collection('group_members')
        .where('memberId', isEqualTo: memberId)
        .get();

    final List<GroupWithMembersDto> groups = [];

    for (final doc in groupMembersSnapshot.docs) {
      final groupId = doc.data()['groupId'] as String;
      final groupSnapshot = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();

      if (groupSnapshot.exists) {
        final groupData = groupSnapshot.data()!;
        groups.add(
          GroupWithMembersDto(
            id: groupId,
            name: groupData['name'] as String,
            members: [],
          ),
        );
      }
    }

    return groups;
  }

  List<GroupWithMembersDto> _mergeUniqueGroups(
    List<GroupWithMembersDto> adminGroups,
    List<GroupWithMembersDto> memberGroups,
  ) {
    final Set<String> groupIds = {};
    final List<GroupWithMembersDto> uniqueGroups = [];

    for (final group in adminGroups) {
      if (!groupIds.contains(group.id)) {
        groupIds.add(group.id);
        uniqueGroups.add(group);
      }
    }

    for (final group in memberGroups) {
      if (!groupIds.contains(group.id)) {
        groupIds.add(group.id);
        uniqueGroups.add(group);
      }
    }

    return uniqueGroups;
  }

  List<GroupWithMembersDto> _sortGroups(
    List<GroupWithMembersDto> groups,
    List<OrderBy>? orderBy,
  ) {
    if (orderBy == null || orderBy.isEmpty) {
      return groups;
    }

    final sortedGroups = List<GroupWithMembersDto>.from(groups);
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

  Future<List<GroupWithMembersDto>> _addMembersToGroups(
    List<GroupWithMembersDto> groups, {
    List<OrderBy>? membersOrderBy,
  }) async {
    final List<GroupWithMembersDto> result = [];

    for (final group in groups) {
      final members = await _getMembersForGroup(
        group.id,
        orderBy: membersOrderBy,
      );
      result.add(
        GroupWithMembersDto(id: group.id, name: group.name, members: members),
      );
    }

    return result;
  }

  Future<List<MemberDto>> _getMembersForGroup(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    final groupMembersSnapshot = await _firestore
        .collection('group_members')
        .where('groupId', isEqualTo: groupId)
        .get();

    final List<MemberDto> members = [];

    for (final doc in groupMembersSnapshot.docs) {
      final memberId = doc.data()['memberId'] as String;
      final memberSnapshot = await _firestore
          .collection('members')
          .doc(memberId)
          .get();

      if (memberSnapshot.exists) {
        members.add(MemberMapper.fromFirestore(memberSnapshot));
      }
    }

    return _sortMembers(members, orderBy);
  }

  List<MemberDto> _sortMembers(
    List<MemberDto> members,
    List<OrderBy>? orderBy,
  ) {
    if (orderBy == null || orderBy.isEmpty) {
      return members;
    }

    final sortedMembers = List<MemberDto>.from(members);
    sortedMembers.sort((a, b) {
      for (final order in orderBy) {
        int comparison = 0;
        if (order.field == 'displayName') {
          comparison = a.displayName.compareTo(b.displayName);
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
