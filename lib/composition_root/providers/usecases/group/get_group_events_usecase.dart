import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/queries/group/group_event_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/application/usecases/group/get_group_events_usecase.dart';

final getGroupEventsUsecaseProvider = Provider<GetGroupEventsUsecase>((ref) {
  return GetGroupEventsUsecase(ref.watch(groupEventQueryServiceProvider));
});
