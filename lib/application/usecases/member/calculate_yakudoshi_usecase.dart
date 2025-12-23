import 'package:flutter_riverpod/flutter_riverpod.dart';

final calculateYakudoshiUsecaseProvider = Provider<CalculateYakudoshiUsecase>((
  ref,
) {
  return CalculateYakudoshiUsecase();
});

class CalculateYakudoshiUsecase {
  String? execute(DateTime? birthday, String? gender, int targetYear) {
    if (birthday == null || gender == null) {
      return null;
    }

    if (gender == 'その他') {
      return null;
    }

    final normalizedGender = _normalizeGender(gender);
    if (normalizedGender == null) {
      return null;
    }

    final kazoeAge = _calculateKazoeAge(birthday, targetYear);
    if (kazoeAge == null) {
      return null;
    }

    final honAges = normalizedGender == '男性'
        ? const [25, 42, 61]
        : const [19, 33, 37];

    if (honAges.contains(kazoeAge)) {
      return '本厄';
    }
    if (honAges.contains(kazoeAge + 1)) {
      return '前厄';
    }
    if (honAges.contains(kazoeAge - 1)) {
      return '後厄';
    }

    return null;
  }

  String? _normalizeGender(String gender) {
    switch (gender) {
      case '男性':
      case 'male':
        return '男性';
      case '女性':
      case 'female':
        return '女性';
      default:
        return null;
    }
  }

  int? _calculateKazoeAge(DateTime birthday, int targetYear) {
    if (targetYear < birthday.year) {
      return null;
    }

    return targetYear - birthday.year + 1;
  }
}
