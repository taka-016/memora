import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/member/member_event_dto.dart';
import 'package:memora/application/queries/member/member_event_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/infrastructure/mappers/member/firestore_member_event_mapper.dart';

class FirestoreMemberEventQueryService implements MemberEventQueryService {
  FirestoreMemberEventQueryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<MemberEventDto>> getMemberEventsByMemberIds(
    List<String> memberIds, {
    List<OrderBy>? orderBy,
  }) async {
    if (memberIds.isEmpty) {
      return [];
    }

    try {
      final results = <MemberEventDto>[];
      for (final chunk in _chunkMemberIds(memberIds)) {
        Query<Map<String, dynamic>> query = _firestore
            .collection('member_events')
            .where('memberId', whereIn: chunk);

        if (orderBy != null && orderBy.isNotEmpty) {
          for (final order in orderBy) {
            query = query.orderBy(order.field, descending: order.descending);
          }
        }

        final snapshot = await query.get();
        results.addAll(
          snapshot.docs.map(FirestoreMemberEventMapper.fromFirestore),
        );
      }
      return results;
    } catch (e, stack) {
      logger.e(
        'FirestoreMemberEventQueryService.getMemberEventsByMemberIds: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  Iterable<List<String>> _chunkMemberIds(List<String> memberIds) sync* {
    const chunkSize = 10;
    for (var index = 0; index < memberIds.length; index += chunkSize) {
      final end = (index + chunkSize).clamp(0, memberIds.length);
      yield memberIds.sublist(index, end);
    }
  }
}
