import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/interfaces/group_query_service.dart';
import 'package:memora/application/dtos/group/group_with_members_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/mappers/member_mapper.dart';
import 'package:memora/core/app_logger.dart';

class FirestoreGroupQueryService implements GroupQueryService {
  final FirebaseFirestore _firestore;

  FirestoreGroupQueryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<GroupWithMembersDto>> getGroupsWithMembersByMemberId(
    String memberId,
  ) async {
    try {
      final adminGroups = await _getGroupsWhereUserIsAdmin(memberId);
      final memberGroups = await _getGroupsWhereUserIsMember(memberId);
      final allGroups = _mergeUniqueGroups(adminGroups, memberGroups);

      return await _addMembersToGroups(allGroups);
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
    String ownerId,
  ) async {
    try {
      final managedGroups = await _getGroupsWhereUserIsAdmin(ownerId);
      return await _addMembersToGroups(managedGroups);
    } catch (e, stack) {
      logger.e(
        'FirestoreGroupQueryService.getManagedGroupsWithMembersByOwnerId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  Future<List<GroupWithMembersDto>> _getGroupsWhereUserIsAdmin(
    String memberId,
  ) async {
    final snapshot = await _firestore
        .collection('groups')
        .where('ownerId', isEqualTo: memberId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return GroupWithMembersDto(
        groupId: doc.id,
        groupName: data['name'] as String,
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
            groupId: groupId,
            groupName: groupData['name'] as String,
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
      if (!groupIds.contains(group.groupId)) {
        groupIds.add(group.groupId);
        uniqueGroups.add(group);
      }
    }

    for (final group in memberGroups) {
      if (!groupIds.contains(group.groupId)) {
        groupIds.add(group.groupId);
        uniqueGroups.add(group);
      }
    }

    return uniqueGroups;
  }

  Future<List<GroupWithMembersDto>> _addMembersToGroups(
    List<GroupWithMembersDto> groups,
  ) async {
    final List<GroupWithMembersDto> result = [];

    for (final group in groups) {
      final members = await _getMembersForGroup(group.groupId);
      result.add(
        GroupWithMembersDto(
          groupId: group.groupId,
          groupName: group.groupName,
          members: members,
        ),
      );
    }

    return result;
  }

  Future<List<MemberDto>> _getMembersForGroup(String groupId) async {
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

    return members;
  }
}
