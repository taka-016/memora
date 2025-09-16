import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class MemberDto extends Equatable {
  const MemberDto({
    required this.id,
    this.accountId,
    this.ownerId,
    this.hiraganaFirstName,
    this.hiraganaLastName,
    this.kanjiFirstName,
    this.kanjiLastName,
    this.firstName,
    this.lastName,
    required this.displayName,
    this.type,
    this.birthday,
    this.gender,
    this.email,
    this.phoneNumber,
    this.passportNumber,
    this.passportExpiration,
  });

  final String id;
  final String? accountId;
  final String? ownerId;
  final String? hiraganaFirstName;
  final String? hiraganaLastName;
  final String? kanjiFirstName;
  final String? kanjiLastName;
  final String? firstName;
  final String? lastName;
  final String displayName;
  final String? type;
  final DateTime? birthday;
  final String? gender;
  final String? email;
  final String? phoneNumber;
  final String? passportNumber;
  final String? passportExpiration;

  MemberDto copyWith({
    String? id,
    String? accountId,
    String? ownerId,
    String? hiraganaFirstName,
    String? hiraganaLastName,
    String? kanjiFirstName,
    String? kanjiLastName,
    String? firstName,
    String? lastName,
    String? displayName,
    String? type,
    DateTime? birthday,
    String? gender,
    String? email,
    String? phoneNumber,
    String? passportNumber,
    String? passportExpiration,
  }) {
    return MemberDto(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      ownerId: ownerId ?? this.ownerId,
      hiraganaFirstName: hiraganaFirstName ?? this.hiraganaFirstName,
      hiraganaLastName: hiraganaLastName ?? this.hiraganaLastName,
      kanjiFirstName: kanjiFirstName ?? this.kanjiFirstName,
      kanjiLastName: kanjiLastName ?? this.kanjiLastName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      type: type ?? this.type,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      passportNumber: passportNumber ?? this.passportNumber,
      passportExpiration: passportExpiration ?? this.passportExpiration,
    );
  }

  factory MemberDto.fromFirestore(Map<String, dynamic> data, String id) {
    final birthdayRaw = data['birthday'];
    DateTime? birthday;
    if (birthdayRaw is Timestamp) {
      birthday = birthdayRaw.toDate();
    } else if (birthdayRaw is DateTime) {
      birthday = birthdayRaw;
    }

    return MemberDto(
      id: id,
      accountId: data['accountId'] as String?,
      ownerId: data['ownerId'] as String?,
      hiraganaFirstName: data['hiraganaFirstName'] as String?,
      hiraganaLastName: data['hiraganaLastName'] as String?,
      kanjiFirstName: data['kanjiFirstName'] as String?,
      kanjiLastName: data['kanjiLastName'] as String?,
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      displayName: data['displayName'] as String? ?? '',
      type: data['type'] as String?,
      birthday: birthday,
      gender: data['gender'] as String?,
      email: data['email'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      passportNumber: data['passportNumber'] as String?,
      passportExpiration: data['passportExpiration'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        accountId,
        ownerId,
        hiraganaFirstName,
        hiraganaLastName,
        kanjiFirstName,
        kanjiLastName,
        firstName,
        lastName,
        displayName,
        type,
        birthday,
        gender,
        email,
        phoneNumber,
        passportNumber,
        passportExpiration,
      ];
}
