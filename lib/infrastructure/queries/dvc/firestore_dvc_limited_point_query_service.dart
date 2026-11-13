import 'package:memora/infrastructure/queries/dvc/firestore_dvc_children_query.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/queries/dvc/dvc_limited_point_query_service.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/mappers/dvc/firestore_dvc_limited_point_mapper.dart';

class FirestoreDvcLimitedPointQueryService
    implements DvcLimitedPointQueryService {
  FirestoreDvcLimitedPointQueryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<DvcLimitedPointDto>> getDvcLimitedPointsByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
    String? contractId,
  }) async {
    try {
      final docs = await firestoreDvcChildren(_firestore, 'dvc_limited_points', groupId, contractId: contractId, orderBy: orderBy);
      return docs.map(FirestoreDvcLimitedPointMapper.fromFirestore).toList();
    } catch (e, stack) {
      logger.e(
        'FirestoreDvcLimitedPointQueryService.getDvcLimitedPointsByGroupId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}
