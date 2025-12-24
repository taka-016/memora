import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/member/calculate_yakudoshi_usecase.dart';

void main() {
  group('CalculateYakudoshiUsecase', () {
    const targetYear = 2025;
    final usecase = CalculateYakudoshiUsecase();

    test('生年月日が未設定の場合はnullを返す', () {
      expect(usecase.execute(null, '男性', targetYear), isNull);
    });

    test('genderがnullの場合はnullを返す', () {
      final birthday = DateTime(2001, 6, 1);
      expect(usecase.execute(birthday, null, targetYear), isNull);
    });

    test('genderがその他の場合はnullを返す', () {
      final birthday = DateTime(2001, 6, 1);
      expect(usecase.execute(birthday, 'その他', targetYear), isNull);
    });

    test('男性の数え年24歳は前厄を返す', () {
      final birthday = DateTime(2002, 6, 1);
      expect(usecase.execute(birthday, '男性', targetYear), '前厄');
    });

    test('男性の数え年25歳は本厄を返す', () {
      final birthday = DateTime(2001, 6, 1);
      expect(usecase.execute(birthday, '男性', targetYear), '本厄');
    });

    test('男性の数え年26歳は後厄を返す', () {
      final birthday = DateTime(2000, 6, 1);
      expect(usecase.execute(birthday, '男性', targetYear), '後厄');
    });

    test('女性の数え年18歳は前厄を返す', () {
      final birthday = DateTime(2008, 6, 1);
      expect(usecase.execute(birthday, '女性', targetYear), '前厄');
    });

    test('女性の数え年19歳は本厄を返す', () {
      final birthday = DateTime(2007, 6, 1);
      expect(usecase.execute(birthday, '女性', targetYear), '本厄');
    });

    test('女性の数え年20歳は後厄を返す', () {
      final birthday = DateTime(2006, 6, 1);
      expect(usecase.execute(birthday, '女性', targetYear), '後厄');
    });

    test('対象外年齢はnullを返す', () {
      final birthday = DateTime(1990, 6, 1);
      expect(usecase.execute(birthday, '男性', targetYear), isNull);
    });
  });
}
