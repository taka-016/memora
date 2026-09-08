import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/group/create_group_usecase.dart';

final createGroupUsecaseProvider = Provider<CreateGroupUsecase>((ref) {
  return CreateGroupUsecase(ref.watch(groupRepositoryProvider));
});
