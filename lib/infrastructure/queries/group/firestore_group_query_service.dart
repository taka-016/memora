import 'package:memora/infrastructure/services/firestore_account_permissions_source.dart';
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

  FirestoreGroupQueryService({
    FirebaseFirestore? firestore,
    FirestoreAccountPermissionsSource? permissions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _permissions =
           permissions ??
           FirestoreAccountPermissionsSource(
             firestore ?? FirebaseFirestore.instance,
           );

  final FirestoreAccountPermissionsSource _permissions;

  @override
  Future<bool> groupExists(String groupId) async =>
      (await _firestore.collection('groups').doc(groupId).get()).exists;

  @override
  Future<List<GroupDto>> getGroupsWithMembersByMemberId(
    String memberId, {
    List<OrderBy>? groupsOrderBy,
    List<OrderBy>? membersOrderBy,
  }) async {
    try {
      final allGroups = await _groupsForCurrentMember(memberId, managed: false);
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
        await _groupsForCurrentMember(ownerId, managed: true),
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
          .get();

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

  Future<List<GroupDto>> _groupsForCurrentMember(
    String memberId, {
    required bool managed,
  }) async {
    final permissions = await _permissions.current();
    if (permissions == null) return [];
    if (permissions.memberId != memberId) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: '本人以外の所属は取得できません',
      );
    }
    final ids = managed
        ? permissions.managedGroupIds
        : permissions.memberGroupIds;
    final groups = <GroupDto>[];
    for (final id in ids) {
      final doc = await _firestore.collection('groups').doc(id).get();
      if (doc.exists) groups.add(FirestoreGroupMapper.fromFirestore(doc));
    }
    return groups;
  }

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
        .get();

    final List<GroupMemberDto> members = [];

    for (final doc in groupMembersSnapshot.docs) {
      final memberId = doc.data()['memberId'] as String;
      final memberSnapshot = await _firestore
          .collection('members')
          .doc(memberId)
          .get();

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
