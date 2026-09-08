import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/member/member_event_dto.dart';
import 'package:memora/application/queries/member/member_event_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/application/usecases/member/get_member_events_usecase.dart';

final getMemberEventsUsecaseProvider = Provider<GetMemberEventsUsecase>((ref) {
  return GetMemberEventsUsecase(ref.watch(memberEventQueryServiceProvider));
});
