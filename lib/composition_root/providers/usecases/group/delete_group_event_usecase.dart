import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/group/delete_group_event_usecase.dart';

final deleteGroupEventUsecaseProvider = Provider<DeleteGroupEventUsecase>((
  ref,
) {
  return DeleteGroupEventUsecase(ref.watch(groupEventRepositoryProvider));
});
