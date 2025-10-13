import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/group_member.dart';
import 'package:memora/domain/repositories/group_repository.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/infrastructure/mappers/firestore_group_mapper.dart';
import 'package:memora/infrastructure/mappers/firestore_group_member_mapper.dart';

class FirestoreGroupRepository implements GroupRepository {
  final FirebaseFirestore _firestore;

  FirestoreGroupRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> saveGroup(Group group) async {
    final batch = _firestore.batch();

    final groupDocRef = _firestore.collection('groups').doc();
    batch.set(groupDocRef, FirestoreGroupMapper.toFirestore(group));

    for (final GroupMember member in group.members) {
      final memberDocRef = _firestore.collection('group_members').doc();
      batch.set(
        memberDocRef,
        FirestoreGroupMemberMapper.toFirestore(
          member.copyWith(groupId: groupDocRef.id),
        ),
      );
    }

    await batch.commit();
    return groupDocRef.id;
  }

  @override
  Future<void> updateGroup(Group group) async {
    final batch = _firestore.batch();

    batch.update(
      _firestore.collection('groups').doc(group.id),
      FirestoreGroupMapper.toFirestore(group),
    );

    final memberSnapshot = await _firestore
        .collection('group_members')
        .where('groupId', isEqualTo: group.id)
        .get();
    for (final doc in memberSnapshot.docs) {
      batch.delete(doc.reference);
    }

    for (final GroupMember member in group.members) {
      final memberDocRef = _firestore.collection('group_members').doc();
      batch.set(
        memberDocRef,
        FirestoreGroupMemberMapper.toFirestore(
          member.copyWith(groupId: group.id),
        ),
      );
    }

    await batch.commit();
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    final batch = _firestore.batch();

    final memberSnapshot = await _firestore
        .collection('group_members')
        .where('groupId', isEqualTo: groupId)
        .get();
    for (final doc in memberSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_firestore.collection('groups').doc(groupId));
    await batch.commit();
  }

  @override
  Future<void> deleteGroupMembersByMemberId(String memberId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('group_members')
        .where('memberId', isEqualTo: memberId)
        .get();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  @override
  Future<List<Group>> getGroups({List<OrderBy>? orderBy}) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('groups');

      // ソート条件が指定されている場合のみ適用
      if (orderBy != null && orderBy.isNotEmpty) {
        for (final order in orderBy) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => FirestoreGroupMapper.fromFirestore(doc))
          .toList();
    } catch (e, stack) {
      logger.e(
        'FirestoreGroupRepository.getGroups: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<Group?> getGroupById(
    String groupId, {
    List<OrderBy>? membersOrderBy,
  }) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      if (!doc.exists) {
        return null;
      }

      Query<Map<String, dynamic>> membersQuery = _firestore
          .collection('group_members')
          .where('groupId', isEqualTo: doc.id);

      // ソート条件が指定されている場合のみ適用
      if (membersOrderBy != null && membersOrderBy.isNotEmpty) {
        for (final order in membersOrderBy) {
          membersQuery = membersQuery.orderBy(
            order.field,
            descending: order.descending,
          );
        }
      }

      final groupMembersSnapshot = await membersQuery.get();

      final groupMembers = groupMembersSnapshot.docs
          .map((doc) => FirestoreGroupMemberMapper.fromFirestore(doc))
          .toList();

      return FirestoreGroupMapper.fromFirestore(doc, members: groupMembers);
    } catch (e, stack) {
      logger.e(
        'FirestoreGroupRepository.getGroups: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  @override
  Future<List<Group>> getGroupsByOwnerId(
    String ownerId, {
    List<OrderBy>? orderBy,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('groups')
          .where('ownerId', isEqualTo: ownerId);

      // ソート条件が指定されている場合のみ適用
      if (orderBy != null && orderBy.isNotEmpty) {
        for (final order in orderBy) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => FirestoreGroupMapper.fromFirestore(doc))
          .toList();
    } catch (e, stack) {
      logger.e(
        'FirestoreGroupRepository.getGroupsByOwnerId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<List<Group>> getGroupsWhereUserIsAdmin(
    String memberId, {
    List<OrderBy>? orderBy,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('groups')
        .where('ownerId', isEqualTo: memberId);

    // ソート条件が指定されている場合のみ適用
    if (orderBy != null && orderBy.isNotEmpty) {
      for (final order in orderBy) {
        query = query.orderBy(order.field, descending: order.descending);
      }
    }

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => FirestoreGroupMapper.fromFirestore(doc))
        .toList();
  }

  @override
  Future<List<Group>> getGroupsWhereUserIsMember(
    String memberId, {
    List<OrderBy>? orderBy,
  }) async {
    final memberGroupsSnapshot = await _firestore
        .collection('group_members')
        .where('memberId', isEqualTo: memberId)
        .get();

    final List<Group> groups = [];
    for (final doc in memberGroupsSnapshot.docs) {
      final groupId = doc.data()['groupId'] as String;
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (groupDoc.exists) {
        final group = FirestoreGroupMapper.fromFirestore(groupDoc);
        groups.add(group);
      }
    }

    // ソート条件が指定されている場合のみ適用
    if (orderBy != null && orderBy.isNotEmpty) {
      groups.sort((a, b) {
        int comparison = 0;
        for (final order in orderBy) {
          final aValue = _getFieldValue(a, order.field);
          final bValue = _getFieldValue(b, order.field);

          if (aValue == null && bValue == null) {
            comparison = 0;
          } else if (aValue == null) {
            comparison = order.descending ? -1 : 1;
          } else if (bValue == null) {
            comparison = order.descending ? 1 : -1;
          } else if (aValue is Comparable && bValue is Comparable) {
            comparison = order.descending
                ? bValue.compareTo(aValue)
                : aValue.compareTo(bValue);
          }

          if (comparison != 0) {
            break;
          }
        }
        return comparison;
      });
    }

    return groups;
  }

  dynamic _getFieldValue(Group group, String field) {
    switch (field) {
      case 'name':
        return group.name;
      case 'ownerId':
        return group.ownerId;
      case 'id':
        return group.id;
      default:
        return null;
    }
  }
}
