import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/mappers/dvc/dvc_point_contract_mapper.dart';
import 'package:memora/application/queries/dvc/dvc_point_contract_query_service.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/domain/value_objects/order_by.dart';

class FirestoreDvcPointContractQueryService
    implements DvcPointContractQueryService {
  FirestoreDvcPointContractQueryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<DvcPointContractDto>> getDvcPointContractsByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('dvc_point_contracts')
          .where('groupId', isEqualTo: groupId);

      if (orderBy != null && orderBy.isNotEmpty) {
        for (final order in orderBy) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs.map(DvcPointContractMapper.fromFirestore).toList();
    } catch (e, stack) {
      logger.e(
        'FirestoreDvcPointContractQueryService.getDvcPointContractsByGroupId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }
}
