import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/group/save_group_event_usecase.dart';

final saveGroupEventUsecaseProvider = Provider<SaveGroupEventUsecase>((ref) {
  return SaveGroupEventUsecase(ref.watch(groupEventRepositoryProvider));
});
