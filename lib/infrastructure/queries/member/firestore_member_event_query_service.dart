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
      _sortResults(results, orderBy);
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
    // Firestoreのinクエリは最大30 disjunctionsまで。
    const chunkSize = 30;
    for (var index = 0; index < memberIds.length; index += chunkSize) {
      final end = (index + chunkSize).clamp(0, memberIds.length).toInt();
      yield memberIds.sublist(index, end);
    }
  }

  void _sortResults(List<MemberEventDto> results, List<OrderBy>? orderBy) {
    if (orderBy == null || orderBy.isEmpty) {
      return;
    }

    results.sort((a, b) {
      for (final order in orderBy) {
        final comparison = _compareByField(a, b, order.field);
        if (comparison != 0) {
          return order.descending ? -comparison : comparison;
        }
      }
      return 0;
    });
  }

  int _compareByField(MemberEventDto a, MemberEventDto b, String field) {
    switch (field) {
      case 'id':
        return a.id.compareTo(b.id);
      case 'memberId':
        return a.memberId.compareTo(b.memberId);
      case 'year':
        return a.year.compareTo(b.year);
      case 'memo':
        return a.memo.compareTo(b.memo);
      default:
        return 0;
    }
  }
}
