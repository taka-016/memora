import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final createMemberUsecaseProvider = Provider<CreateMemberUsecase>((ref) {
  return CreateMemberUsecase(ref.watch(memberRepositoryProvider));
});

class CreateMemberUsecase {
  final MemberRepository _memberRepository;

  CreateMemberUsecase(this._memberRepository);

  Future<void> execute(Member editedMember, String ownerId) async {
    final newMember = Member(
      id: const Uuid().v4(),
      accountId: editedMember.accountId,
      ownerId: ownerId,
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
    );

    await _memberRepository.saveMember(newMember);
  }
}
