import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/member/calculate_school_grade_usecase.dart';

void main() {
  group('CalculateSchoolGradeUsecase', () {
    const targetYear = 2025;
    final usecase = CalculateSchoolGradeUsecase();

    test('生年月日が未設定の場合はnullを返す', () {
      expect(usecase.execute(null, targetYear), isNull);
    });

    test('対象年より未来の生年月日はnullを返す', () {
      final birthday = DateTime(2030, 4, 1);
      expect(usecase.execute(birthday, targetYear), isNull);
    });

    test('生まれた年が4月1日以降なら新生児を返す', () {
      final birthday = DateTime(2022, 6, 1);
      expect(usecase.execute(birthday, 2022), '新生児');
    });

    test('生まれた年が1月1日から3月31日までなら新生児/0歳を返す', () {
      final birthday = DateTime(2022, 3, 31);
      expect(usecase.execute(birthday, 2022), '新生児/0歳児');
    });

    test('3月31日時点で0歳なら0歳を返す', () {
      final birthday = DateTime(2024, 4, 1);
      expect(usecase.execute(birthday, targetYear), '0歳児');
    });

    test('3月31日時点で1歳なら1歳を返す', () {
      final birthday = DateTime(2023, 4, 1);
      expect(usecase.execute(birthday, targetYear), '1歳児');
    });

    test('3月31日時点で3歳なら年少を返す', () {
      final birthday = DateTime(2021, 4, 1);
      expect(usecase.execute(birthday, targetYear), '年少');
    });

    test('3月31日時点で4歳なら年中を返す', () {
      final birthday = DateTime(2020, 4, 1);
      expect(usecase.execute(birthday, targetYear), '年中');
    });

    test('3月31日時点で5歳なら年長を返す', () {
      final birthday = DateTime(2019, 4, 1);
      expect(usecase.execute(birthday, targetYear), '年長');
    });

    test('3月31日時点で6歳なら小1を返す', () {
      final birthday = DateTime(2018, 4, 1);
      expect(usecase.execute(birthday, targetYear), '小学1年生');
    });

    test('3月31日時点で7歳なら小2を返す', () {
      final birthday = DateTime(2017, 4, 1);
      expect(usecase.execute(birthday, targetYear), '小学2年生');
    });

    test('3月31日時点で11歳なら小6を返す', () {
      final birthday = DateTime(2013, 4, 1);
      expect(usecase.execute(birthday, targetYear), '小学6年生');
    });

    test('3月31日時点で12歳なら中1を返す', () {
      final birthday = DateTime(2012, 4, 1);
      expect(usecase.execute(birthday, targetYear), '中学1年生');
    });

    test('3月31日時点で14歳なら中3を返す', () {
      final birthday = DateTime(2010, 4, 1);
      expect(usecase.execute(birthday, targetYear), '中学3年生');
    });

    test('3月31日時点で15歳なら高1を返す', () {
      final birthday = DateTime(2009, 4, 1);
      expect(usecase.execute(birthday, targetYear), '高校1年生');
    });

    test('3月31日時点で17歳なら高3を返す', () {
      final birthday = DateTime(2007, 4, 1);
      expect(usecase.execute(birthday, targetYear), '高校3年生');
    });

    test('3月31日時点で18歳なら大1を返す', () {
      final birthday = DateTime(2006, 4, 1);
      expect(usecase.execute(birthday, targetYear), '大学1年生');
    });

    test('3月31日時点で21歳なら大4を返す', () {
      final birthday = DateTime(2003, 4, 1);
      expect(usecase.execute(birthday, targetYear), '大学4年生');
    });

    test('3月31日時点で22歳以上はnullを返す', () {
      final birthday = DateTime(2002, 4, 1);
      expect(usecase.execute(birthday, targetYear), isNull);
    });
  });
}
