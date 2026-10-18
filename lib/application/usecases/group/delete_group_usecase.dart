import 'package:memora/domain/repositories/group/group_repository.dart';

class DeleteGroupUsecase {
  final GroupRepository _groupRepository;

  DeleteGroupUsecase(this._groupRepository);

  Future<void> execute(String groupId, {int? expectedVersion}) async {
    await _groupRepository.deleteGroup(
      groupId,
      expectedVersion: expectedVersion,
    );
  }
}
