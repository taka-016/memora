import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/member/member.dart';

class FirestoreMemberMapper {
  static Map<String, dynamic> toFirestore(Member member) {
    return {
      'accountId': member.accountId,
      'ownerId': member.ownerId,
      'hiraganaFirstName': member.hiraganaFirstName,
      'hiraganaLastName': member.hiraganaLastName,
      'kanjiFirstName': member.kanjiFirstName,
      'kanjiLastName': member.kanjiLastName,
      'firstName': member.firstName,
      'lastName': member.lastName,
      'displayName': member.displayName,
      'type': member.type,
      'birthday': member.birthday != null
          ? Timestamp.fromDate(member.birthday!)
          : null,
      'gender': member.gender,
      'email': member.email,
      'phoneNumber': member.phoneNumber,
      'passportNumber': member.passportNumber,
      'passportExpiration': member.passportExpiration,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
