import '../../domain/entities/member.dart';
import '../../domain/repositories/member_repository.dart';

class CreateMemberUsecase {
  final MemberRepository _memberRepository;

  CreateMemberUsecase(this._memberRepository);

  Future<void> execute(Member administratorMember, Member newMemberData) async {
    final memberToSave = Member(
      id: newMemberData.id,
      accountId: newMemberData.accountId,
      administratorId: administratorMember.id,
      hiraganaFirstName: newMemberData.hiraganaFirstName,
      hiraganaLastName: newMemberData.hiraganaLastName,
      kanjiFirstName: newMemberData.kanjiFirstName,
      kanjiLastName: newMemberData.kanjiLastName,
      firstName: newMemberData.firstName,
      lastName: newMemberData.lastName,
      nickname: newMemberData.nickname,
      type: newMemberData.type,
      birthday: newMemberData.birthday,
      gender: newMemberData.gender,
      email: newMemberData.email,
      phoneNumber: newMemberData.phoneNumber,
      passportNumber: newMemberData.passportNumber,
      passportExpiration: newMemberData.passportExpiration,
      anaMileageNumber: newMemberData.anaMileageNumber,
      jalMileageNumber: newMemberData.jalMileageNumber,
    );

    await _memberRepository.saveMember(memberToSave);
  }
}
