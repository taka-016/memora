import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/infrastructure/database/sqlite_values.dart';

class SqliteMemberMapper {
  static MemberDto fromRow(Map<String, Object?> row) => MemberDto(
    id: row['id'] as String,
    accountId: row['account_id'] as String?,
    ownerId: row['owner_id'] as String?,
    hiraganaFirstName: row['hiragana_first_name'] as String?,
    hiraganaLastName: row['hiragana_last_name'] as String?,
    kanjiFirstName: row['kanji_first_name'] as String?,
    kanjiLastName: row['kanji_last_name'] as String?,
    firstName: row['first_name'] as String?,
    lastName: row['last_name'] as String?,
    displayName: row['display_name'] as String,
    type: row['type'] as String?,
    birthday: SqliteValues.date(row['birthday']),
    gender: row['gender'] as String?,
    email: row['email'] as String?,
    phoneNumber: row['phone_number'] as String?,
  );
  static Map<String, Object?> toRow(Member value) => {
    'id': value.id,
    'account_id': value.accountId,
    'owner_id': value.ownerId,
    'hiragana_first_name': value.hiraganaFirstName,
    'hiragana_last_name': value.hiraganaLastName,
    'kanji_first_name': value.kanjiFirstName,
    'kanji_last_name': value.kanjiLastName,
    'first_name': value.firstName,
    'last_name': value.lastName,
    'display_name': value.displayName,
    'type': value.type,
    'birthday': value.birthday?.microsecondsSinceEpoch,
    'gender': value.gender,
    'email': value.email,
    'phone_number': value.phoneNumber,
  };
}
