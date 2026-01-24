import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/queries/trip/task_query_service.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getTasksByTripIdUsecaseProvider = Provider<GetTasksByTripIdUsecase>((
  ref,
) {
  return GetTasksByTripIdUsecase(ref.watch(taskQueryServiceProvider));
});

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
