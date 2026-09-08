import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/queries/trip/task_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/application/usecases/trip/get_tasks_by_trip_id_usecase.dart';

final getTasksByTripIdUsecaseProvider = Provider<GetTasksByTripIdUsecase>((
  ref,
) {
  return GetTasksByTripIdUsecase(ref.watch(taskQueryServiceProvider));
});
