import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/member.dart';

void main() {
  group('Member', () {
    test('インスタンス生成が正しく行われる', () {
      final now = DateTime(2000, 1, 1);
      final member = Member(
        id: 'member001',
        accountId: 'account001',
        administratorId: 'admin001',
        hiraganaFirstName: 'たろう',
        hiraganaLastName: 'やまだ',
        kanjiFirstName: '太郎',
        kanjiLastName: '山田',
        firstName: 'Taro',
        lastName: 'Yamada',
        displayName: 'たろちゃん',
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
      expect(member.administratorId, 'admin001');
      expect(member.hiraganaFirstName, 'たろう');
      expect(member.hiraganaLastName, 'やまだ');
      expect(member.kanjiFirstName, '太郎');
      expect(member.kanjiLastName, '山田');
      expect(member.firstName, 'Taro');
      expect(member.lastName, 'Yamada');
      expect(member.displayName, 'たろちゃん');
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
      final member = Member(id: 'member002', displayName: 'たろちゃん');
      expect(member.id, 'member002');
      expect(member.accountId, null);
      expect(member.administratorId, null);
      expect(member.hiraganaFirstName, null);
      expect(member.hiraganaLastName, null);
      expect(member.kanjiFirstName, null);
      expect(member.kanjiLastName, null);
      expect(member.firstName, null);
      expect(member.lastName, null);
      expect(member.displayName, 'たろちゃん');
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

    test('同じプロパティを持つインスタンス同士は等価である', () {
      final now = DateTime(2000, 1, 1);
      final member1 = Member(
        id: 'member001',
        accountId: 'account001',
        administratorId: 'admin001',
        displayName: 'たろちゃん',
        birthday: now,
        email: 'taro@example.com',
      );
      final member2 = Member(
        id: 'member001',
        accountId: 'account001',
        administratorId: 'admin001',
        displayName: 'たろちゃん',
        birthday: now,
        email: 'taro@example.com',
      );
      expect(member1, equals(member2));
    });

    test('異なるプロパティを持つインスタンス同士は等価でない', () {
      final now = DateTime(2000, 1, 1);
      final member1 = Member(
        id: 'member001',
        displayName: 'たろちゃん',
        birthday: now,
      );
      final member2 = Member(
        id: 'member002',
        displayName: 'たろちゃん',
        birthday: now,
      );
      expect(member1, isNot(equals(member2)));
    });

    test('copyWithメソッドが正しく動作する', () {
      final now = DateTime(2000, 1, 1);
      final member = Member(
        id: 'member001',
        accountId: 'account001',
        displayName: 'たろちゃん',
        email: 'taro@example.com',
        birthday: now,
      );
      final updatedMember = member.copyWith(
        displayName: '新しい名前',
        email: 'new@example.com',
      );
      expect(updatedMember.id, 'member001');
      expect(updatedMember.accountId, 'account001');
      expect(updatedMember.displayName, '新しい名前');
      expect(updatedMember.email, 'new@example.com');
      expect(updatedMember.birthday, now);
    });

    test('copyWithメソッドで変更しないフィールドは元の値が保持される', () {
      final member = Member(
        id: 'member001',
        displayName: 'たろちゃん',
        email: 'taro@example.com',
      );
      final updatedMember = member.copyWith(displayName: '新しい名前');
      expect(updatedMember.id, 'member001');
      expect(updatedMember.displayName, '新しい名前');
      expect(updatedMember.email, 'taro@example.com');
    });
  });
}
