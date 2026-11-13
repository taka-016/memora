import 'package:memora/infrastructure/queries/dvc/firestore_dvc_children_query.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/queries/dvc/dvc_point_usage_query_service.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/mappers/dvc/firestore_dvc_point_usage_mapper.dart';

class FirestoreDvcPointUsageQueryService implements DvcPointUsageQueryService {
  FirestoreDvcPointUsageQueryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<DvcPointUsageDto>> getDvcPointUsagesByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
    String? contractId,
  }) async {
    try {
      final docs = await firestoreDvcChildren(_firestore, 'dvc_point_usages', groupId, contractId: contractId, orderBy: orderBy);
      return docs.map(FirestoreDvcPointUsageMapper.fromFirestore).toList();
    } catch (e, stack) {
      logger.e(
        'FirestoreDvcPointUsageQueryService.getDvcPointUsagesByGroupId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}
