class Member {
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

  Member({
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
}
