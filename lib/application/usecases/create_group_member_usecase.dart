import '../../domain/entities/group_member.dart';
import '../../domain/repositories/group_member_repository.dart';

class CreateGroupMemberUsecase {
  final GroupMemberRepository _repository;

  CreateGroupMemberUsecase(this._repository);

  Future<void> execute(GroupMember groupMember) async {
    await _repository.saveGroupMember(groupMember);
  }
}
