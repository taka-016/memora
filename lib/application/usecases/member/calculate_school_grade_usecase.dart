import 'package:flutter_riverpod/flutter_riverpod.dart';

final calculateSchoolGradeUsecaseProvider =
    Provider<CalculateSchoolGradeUsecase>((ref) {
      return CalculateSchoolGradeUsecase();
    });

class CalculateSchoolGradeUsecase {
  String? execute(DateTime? birthday, int targetYear) {
    if (birthday == null) {
      return null;
    }

    if (targetYear < birthday.year) {
      return null;
    }

    if (targetYear == birthday.year) {
      if (birthday.month <= 3) {
        return '新生児/0歳児';
      }
      return '新生児';
    }

    final age = _calculateAgeOnMarch31(birthday, targetYear);
    if (age < 0) {
      return null;
    }

    if (age == 0) {
      return '0歳児';
    }

    if (age >= 1 && age <= 2) {
      return '$age歳児';
    }

    if (age == 3) {
      return '年少';
    }

    if (age == 4) {
      return '年中';
    }

    if (age == 5) {
      return '年長';
    }

    if (age >= 6 && age <= 11) {
      return '小学${age - 5}年生';
    }

    if (age >= 12 && age <= 14) {
      return '中学${age - 11}年生';
    }

    if (age >= 15 && age <= 17) {
      return '高校${age - 14}年生';
    }

    if (age >= 18 && age <= 21) {
      return '大学${age - 17}年生';
    }

    return null;
  }

  int _calculateAgeOnMarch31(DateTime birthday, int targetYear) {
    var age = targetYear - birthday.year;
    if (birthday.month > 3) {
      age -= 1;
    }
    return age;
  }
}
