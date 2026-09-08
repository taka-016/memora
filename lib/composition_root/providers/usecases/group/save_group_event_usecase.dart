import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/mappers/group/group_event_mapper.dart';
import 'package:memora/domain/repositories/group/group_event_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/group/save_group_event_usecase.dart';

final saveGroupEventUsecaseProvider = Provider<SaveGroupEventUsecase>((ref) {
  return SaveGroupEventUsecase(ref.watch(groupEventRepositoryProvider));
});
