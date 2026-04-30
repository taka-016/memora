import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/repositories/member/member_event_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final deleteMemberEventUsecaseProvider = Provider<DeleteMemberEventUsecase>((
  ref,
) {
  return DeleteMemberEventUsecase(ref.watch(memberEventRepositoryProvider));
});

class DeleteMemberEventUsecase {
  final MemberEventRepository _memberEventRepository;

  DeleteMemberEventUsecase(this._memberEventRepository);

  Future<void> execute(String memberEventId) async {
    await _memberEventRepository.deleteMemberEvent(memberEventId);
  }
}
