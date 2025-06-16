class Member {
  final String id;
  final String hiraganaFirstName;
  final String hiraganaLastName;
  final String kanjiFirstName;
  final String kanjiLastName;
  final String firstName;
  final String lastName;
  final String? nickname;
  final String type;
  final DateTime birthday;
  final String gender;
  final String? email;
  final String? phoneNumber;
  final String? passportNumber;
  final String? passportExpiration;
  final String? anaMileageNumber;
  final String? jalMileageNumber;

  Member({
    required this.id,
    required this.hiraganaFirstName,
    required this.hiraganaLastName,
    required this.kanjiFirstName,
    required this.kanjiLastName,
    required this.firstName,
    required this.lastName,
    this.nickname,
    required this.type,
    required this.birthday,
    required this.gender,
    this.email,
    this.phoneNumber,
    this.passportNumber,
    this.passportExpiration,
    this.anaMileageNumber,
    this.jalMileageNumber,
  });
}
