import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/group/update_group_usecase.dart';

final updateGroupUsecaseProvider = Provider<UpdateGroupUsecase>((ref) {
  return UpdateGroupUsecase(ref.watch(groupRepositoryProvider));
});
