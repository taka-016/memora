import '../dtos/member/member_dto.dart';
import '../../domain/entities/member.dart';

class MemberMapper {
  static MemberDto toDto(Member entity) {
    return MemberDto(
      id: entity.id,
      accountId: entity.accountId,
      ownerId: entity.ownerId,
      hiraganaFirstName: entity.hiraganaFirstName,
      hiraganaLastName: entity.hiraganaLastName,
      kanjiFirstName: entity.kanjiFirstName,
      kanjiLastName: entity.kanjiLastName,
      firstName: entity.firstName,
      lastName: entity.lastName,
      displayName: entity.displayName,
      type: entity.type,
      birthday: entity.birthday,
      gender: entity.gender,
      email: entity.email,
      phoneNumber: entity.phoneNumber,
      passportNumber: entity.passportNumber,
      passportExpiration: entity.passportExpiration,
    );
  }

  static Member toEntity(MemberDto dto) {
    return Member(
      id: dto.id,
      accountId: dto.accountId,
      ownerId: dto.ownerId,
      hiraganaFirstName: dto.hiraganaFirstName,
      hiraganaLastName: dto.hiraganaLastName,
      kanjiFirstName: dto.kanjiFirstName,
      kanjiLastName: dto.kanjiLastName,
      firstName: dto.firstName,
      lastName: dto.lastName,
      displayName: dto.displayName,
      type: dto.type,
      birthday: dto.birthday,
      gender: dto.gender,
      email: dto.email,
      phoneNumber: dto.phoneNumber,
      passportNumber: dto.passportNumber,
      passportExpiration: dto.passportExpiration,
    );
  }

  static List<MemberDto> toDtoList(List<Member> entities) {
    return entities.map(toDto).toList();
  }

  static List<Member> toEntityList(List<MemberDto> dtos) {
    return dtos.map(toEntity).toList();
  }
}
