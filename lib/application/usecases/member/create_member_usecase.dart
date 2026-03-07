import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/mappers/member/member_mapper.dart';
import 'package:uuid/uuid.dart';
import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final createMemberUsecaseProvider = Provider<CreateMemberUsecase>((ref) {
  return CreateMemberUsecase(ref.watch(memberRepositoryProvider));
});

class CreateMemberUsecase {
  final MemberRepository _memberRepository;

  CreateMemberUsecase(this._memberRepository);

  Future<void> execute(MemberDto editedMember, String ownerId) async {
    final editedMemberEntity = MemberMapper.toEntity(editedMember);
    final newMember = Member(
      id: const Uuid().v4(),
      accountId: editedMemberEntity.accountId,
      ownerId: ownerId,
      displayName: editedMemberEntity.displayName,
      kanjiLastName: editedMemberEntity.kanjiLastName,
      kanjiFirstName: editedMemberEntity.kanjiFirstName,
      hiraganaLastName: editedMemberEntity.hiraganaLastName,
      hiraganaFirstName: editedMemberEntity.hiraganaFirstName,
      firstName: editedMemberEntity.firstName,
      lastName: editedMemberEntity.lastName,
      gender: editedMemberEntity.gender,
      birthday: editedMemberEntity.birthday,
      email: editedMemberEntity.email,
      phoneNumber: editedMemberEntity.phoneNumber,
      type: editedMemberEntity.type,
      passportNumber: editedMemberEntity.passportNumber,
      passportExpiration: editedMemberEntity.passportExpiration,
    );

    await _memberRepository.saveMember(newMember);
  }
}
