import '../../../domain/repositories/group_member_repository.dart';

class DeleteGroupMembersByGroupIdUsecase {
  final GroupMemberRepository _repository;

  DeleteGroupMembersByGroupIdUsecase(this._repository);

  Future<void> execute(String groupId) async {
    await _repository.deleteGroupMembersByGroupId(groupId);
  }
}
