import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/member.dart';

class FirestoreMemberMapper {
  static Member fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Member(
      id: doc.id,
      accountId: data?['accountId'] as String?,
      hiraganaFirstName: data?['hiraganaFirstName'] as String?,
      hiraganaLastName: data?['hiraganaLastName'] as String?,
      kanjiFirstName: data?['kanjiFirstName'] as String?,
      kanjiLastName: data?['kanjiLastName'] as String?,
      firstName: data?['firstName'] as String?,
      lastName: data?['lastName'] as String?,
      nickname: data?['nickname'] as String?,
      type: data?['type'] as String?,
      birthday: (data?['birthday'] as Timestamp?)?.toDate(),
      gender: data?['gender'] as String?,
      email: data?['email'] as String?,
      phoneNumber: data?['phoneNumber'] as String?,
      passportNumber: data?['passportNumber'] as String?,
      passportExpiration: data?['passportExpiration'] as String?,
      anaMileageNumber: data?['anaMileageNumber'] as String?,
      jalMileageNumber: data?['jalMileageNumber'] as String?,
    );
  }

  static Map<String, dynamic> toFirestore(Member member) {
    return {
      'accountId': member.accountId,
      'hiraganaFirstName': member.hiraganaFirstName,
      'hiraganaLastName': member.hiraganaLastName,
      'kanjiFirstName': member.kanjiFirstName,
      'kanjiLastName': member.kanjiLastName,
      'firstName': member.firstName,
      'lastName': member.lastName,
      'nickname': member.nickname,
      'type': member.type,
      'birthday': member.birthday != null
          ? Timestamp.fromDate(member.birthday!)
          : null,
      'gender': member.gender,
      'email': member.email,
      'phoneNumber': member.phoneNumber,
      'passportNumber': member.passportNumber,
      'passportExpiration': member.passportExpiration,
      'anaMileageNumber': member.anaMileageNumber,
      'jalMileageNumber': member.jalMileageNumber,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
