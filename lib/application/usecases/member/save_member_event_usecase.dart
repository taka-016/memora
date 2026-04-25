import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/member/member_event_dto.dart';
import 'package:memora/application/mappers/member/member_event_mapper.dart';
import 'package:memora/domain/repositories/member/member_event_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final saveMemberEventUsecaseProvider = Provider<SaveMemberEventUsecase>((ref) {
  return SaveMemberEventUsecase(ref.watch(memberEventRepositoryProvider));
});

class SaveMemberEventUsecase {
  final MemberEventRepository _memberEventRepository;

  SaveMemberEventUsecase(this._memberEventRepository);

  Future<MemberEventDto> execute(MemberEventDto memberEvent) async {
    final entity = MemberEventMapper.toEntity(memberEvent);
    final savedId = await _memberEventRepository.saveMemberEvent(entity);
    return memberEvent.copyWith(id: savedId);
  }
}
