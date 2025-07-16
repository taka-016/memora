import 'package:uuid/uuid.dart';
import '../../domain/entities/member.dart';
import '../../domain/repositories/member_repository.dart';

class CreateMemberUsecase {
  final MemberRepository _memberRepository;

  CreateMemberUsecase(this._memberRepository);

  Future<void> execute(Member editedMember, String administratorId) async {
    final newMember = Member(
      id: const Uuid().v4(),
      accountId: editedMember.accountId,
      administratorId: administratorId,
      displayName: editedMember.displayName,
      kanjiLastName: editedMember.kanjiLastName,
      kanjiFirstName: editedMember.kanjiFirstName,
      hiraganaLastName: editedMember.hiraganaLastName,
      hiraganaFirstName: editedMember.hiraganaFirstName,
      firstName: editedMember.firstName,
      lastName: editedMember.lastName,
      gender: editedMember.gender,
      birthday: editedMember.birthday,
      email: editedMember.email,
      phoneNumber: editedMember.phoneNumber,
      type: editedMember.type,
      passportNumber: editedMember.passportNumber,
      passportExpiration: editedMember.passportExpiration,
      anaMileageNumber: editedMember.anaMileageNumber,
      jalMileageNumber: editedMember.jalMileageNumber,
    );

    await _memberRepository.saveMember(newMember);
  }
}
