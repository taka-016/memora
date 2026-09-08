import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/group/delete_group_usecase.dart';

final deleteGroupUsecaseProvider = Provider<DeleteGroupUsecase>((ref) {
  return DeleteGroupUsecase(
    ref.watch(groupRepositoryProvider),
    ref.watch(groupEventRepositoryProvider),
    ref.watch(tripEntryRepositoryProvider),
  );
});
