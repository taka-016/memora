import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/member.dart';

void main() {
  group('Member', () {
    test('インスタンス生成が正しく行われる', () {
      final now = DateTime(2000, 1, 1);
      final member = Member(
        id: 'member001',
        accountId: 'account001',
        hiraganaFirstName: 'たろう',
        hiraganaLastName: 'やまだ',
        kanjiFirstName: '太郎',
        kanjiLastName: '山田',
        firstName: 'Taro',
        lastName: 'Yamada',
        nickname: 'たろちゃん',
        type: '一般',
        birthday: now,
        gender: 'male',
        email: 'taro@example.com',
        phoneNumber: '090-1234-5678',
        passportNumber: 'A1234567',
        passportExpiration: '2030-01-01',
        anaMileageNumber: 'ANA123456',
        jalMileageNumber: 'JAL123456',
      );
      expect(member.id, 'member001');
      expect(member.accountId, 'account001');
      expect(member.hiraganaFirstName, 'たろう');
      expect(member.hiraganaLastName, 'やまだ');
      expect(member.kanjiFirstName, '太郎');
      expect(member.kanjiLastName, '山田');
      expect(member.firstName, 'Taro');
      expect(member.lastName, 'Yamada');
      expect(member.nickname, 'たろちゃん');
      expect(member.type, '一般');
      expect(member.birthday, now);
      expect(member.gender, 'male');
      expect(member.email, 'taro@example.com');
      expect(member.phoneNumber, '090-1234-5678');
      expect(member.passportNumber, 'A1234567');
      expect(member.passportExpiration, '2030-01-01');
      expect(member.anaMileageNumber, 'ANA123456');
      expect(member.jalMileageNumber, 'JAL123456');
    });

    test('nullableなフィールドがnullの場合でもインスタンス生成が正しく行われる', () {
      final member = Member(id: 'member002');
      expect(member.id, 'member002');
      expect(member.accountId, null);
      expect(member.hiraganaFirstName, null);
      expect(member.hiraganaLastName, null);
      expect(member.kanjiFirstName, null);
      expect(member.kanjiLastName, null);
      expect(member.firstName, null);
      expect(member.lastName, null);
      expect(member.nickname, null);
      expect(member.type, null);
      expect(member.birthday, null);
      expect(member.gender, null);
      expect(member.email, null);
      expect(member.phoneNumber, null);
      expect(member.passportNumber, null);
      expect(member.passportExpiration, null);
      expect(member.anaMileageNumber, null);
      expect(member.jalMileageNumber, null);
    });
  });
}
