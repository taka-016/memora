import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/domain/value_objects/order_by.dart';

abstract class TaskQueryService {
  Future<List<TaskDto>> getTasksByTripId(
    String tripId, {
    List<OrderBy>? orderBy,
  });
}
