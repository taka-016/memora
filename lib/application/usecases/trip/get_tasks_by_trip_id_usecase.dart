import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/queries/trip/task_query_service.dart';
import 'package:memora/application/queries/order_by.dart';

class GetTasksByTripIdUsecase {
  GetTasksByTripIdUsecase(this._taskQueryService);

  final TaskQueryService _taskQueryService;

  Future<List<TaskDto>> execute(String tripId) async {
    return await _taskQueryService.getTasksByTripId(
      tripId,
      orderBy: [const OrderBy('orderIndex', descending: false)],
    );
  }
}
