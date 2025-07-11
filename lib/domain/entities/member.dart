import 'package:equatable/equatable.dart';

class Member extends Equatable {
  const Member({
    required this.id,
    this.accountId,
    this.administratorId,
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
    this.anaMileageNumber,
    this.jalMileageNumber,
  });

  final String id;
  final String? accountId;
  final String? administratorId;
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
  final String? anaMileageNumber;
  final String? jalMileageNumber;

  Member copyWith({
    String? id,
    String? accountId,
    String? administratorId,
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
    String? anaMileageNumber,
    String? jalMileageNumber,
  }) {
    return Member(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      administratorId: administratorId ?? this.administratorId,
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
      anaMileageNumber: anaMileageNumber ?? this.anaMileageNumber,
      jalMileageNumber: jalMileageNumber ?? this.jalMileageNumber,
    );
  }

  @override
  List<Object?> get props => [
    id,
    accountId,
    administratorId,
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
    anaMileageNumber,
    jalMileageNumber,
  ];
}
