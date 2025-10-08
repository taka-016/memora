import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/repositories/group_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final createGroupUsecaseProvider = Provider<CreateGroupUsecase>((ref) {
  return CreateGroupUsecase(ref.watch(groupRepositoryProvider));
});

class CreateGroupUsecase {
  final GroupRepository _groupRepository;

  CreateGroupUsecase(this._groupRepository);

  Future<String> execute(Group group) async {
    return await _groupRepository.saveGroup(group);
  }
}
