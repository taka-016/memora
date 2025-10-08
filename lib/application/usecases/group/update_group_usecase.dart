import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/repositories/group_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final updateGroupUsecaseProvider = Provider<UpdateGroupUsecase>((ref) {
  return UpdateGroupUsecase(ref.watch(groupRepositoryProvider));
});

class UpdateGroupUsecase {
  final GroupRepository _groupRepository;

  UpdateGroupUsecase(this._groupRepository);

  Future<void> execute(Group updatedGroup) async {
    await _groupRepository.updateGroup(updatedGroup);
  }
}
