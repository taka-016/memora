import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/infrastructure/mappers/member/firestore_member_mapper.dart';

class FirestoreMemberQueryService implements MemberQueryService {
  final FirebaseFirestore _firestore;

  FirestoreMemberQueryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Member>> getMembers({List<OrderBy>? orderBy}) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('members');

      if (orderBy != null && orderBy.isNotEmpty) {
        for (final order in orderBy) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => FirestoreMemberMapper.fromFirestore(doc))
          .toList();
    } catch (e, stack) {
      logger.e(
        'FirestoreMemberQueryService.getMembers: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<Member?> getMemberById(String memberId) async {
    try {
      final doc = await _firestore.collection('members').doc(memberId).get();
      if (doc.exists) {
        return FirestoreMemberMapper.fromFirestore(doc);
      }
      return null;
    } catch (e, stack) {
      logger.e(
        'FirestoreMemberQueryService.getMemberById: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  @override
  Future<Member?> getMemberByAccountId(String accountId) async {
    try {
      final querySnapshot = await _firestore
          .collection('members')
          .where('accountId', isEqualTo: accountId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return FirestoreMemberMapper.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e, stack) {
      logger.e(
        'FirestoreMemberQueryService.getMemberByAccountId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  @override
  Future<List<Member>> getMembersByOwnerId(
    String ownerId, {
    List<OrderBy>? orderBy,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('members')
          .where('ownerId', isEqualTo: ownerId);

      if (orderBy != null && orderBy.isNotEmpty) {
        for (final order in orderBy) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => FirestoreMemberMapper.fromFirestore(doc))
          .toList();
    } catch (e, stack) {
      logger.e(
        'FirestoreMemberQueryService.getMembersByOwnerId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }
}
