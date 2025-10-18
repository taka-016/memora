import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_dto.dart';

void main() {
  group('MemberDto', () {
    test('必須パラメータでコンストラクタが正しく動作する', () {
      // Arrange
      const id = 'member-123';
      const displayName = '山田太郎';

      // Act
      final dto = MemberDto(id: id, displayName: displayName);

      // Assert
      expect(dto.id, id);
      expect(dto.displayName, displayName);
      expect(dto.accountId, isNull);
      expect(dto.ownerId, isNull);
      expect(dto.hiraganaFirstName, isNull);
      expect(dto.hiraganaLastName, isNull);
      expect(dto.kanjiFirstName, isNull);
      expect(dto.kanjiLastName, isNull);
      expect(dto.firstName, isNull);
      expect(dto.lastName, isNull);
      expect(dto.type, isNull);
      expect(dto.birthday, isNull);
      expect(dto.gender, isNull);
      expect(dto.email, isNull);
      expect(dto.phoneNumber, isNull);
      expect(dto.passportNumber, isNull);
      expect(dto.passportExpiration, isNull);
    });

    test('全パラメータでコンストラクタが正しく動作する', () {
      // Arrange
      const id = 'member-123';
      const accountId = 'account-456';
      const ownerId = 'owner-789';
      const hiraganaFirstName = 'たろう';
      const hiraganaLastName = 'やまだ';
      const kanjiFirstName = '太郎';
      const kanjiLastName = '山田';
      const firstName = 'Taro';
      const lastName = 'Yamada';
      const displayName = '山田太郎';
      const type = 'adult';
      final birthday = DateTime(1990, 1, 1);
      const gender = 'male';
      const email = 'yamada@example.com';
      const phoneNumber = '090-1234-5678';
      const passportNumber = 'AB1234567';
      const passportExpiration = '2030-12-31';

      // Act
      final dto = MemberDto(
        id: id,
        accountId: accountId,
        ownerId: ownerId,
        hiraganaFirstName: hiraganaFirstName,
        hiraganaLastName: hiraganaLastName,
        kanjiFirstName: kanjiFirstName,
        kanjiLastName: kanjiLastName,
        firstName: firstName,
        lastName: lastName,
        displayName: displayName,
        type: type,
        birthday: birthday,
        gender: gender,
        email: email,
        phoneNumber: phoneNumber,
        passportNumber: passportNumber,
        passportExpiration: passportExpiration,
      );

      // Assert
      expect(dto.id, id);
      expect(dto.accountId, accountId);
      expect(dto.ownerId, ownerId);
      expect(dto.hiraganaFirstName, hiraganaFirstName);
      expect(dto.hiraganaLastName, hiraganaLastName);
      expect(dto.kanjiFirstName, kanjiFirstName);
      expect(dto.kanjiLastName, kanjiLastName);
      expect(dto.firstName, firstName);
      expect(dto.lastName, lastName);
      expect(dto.displayName, displayName);
      expect(dto.type, type);
      expect(dto.birthday, birthday);
      expect(dto.gender, gender);
      expect(dto.email, email);
      expect(dto.phoneNumber, phoneNumber);
      expect(dto.passportNumber, passportNumber);
      expect(dto.passportExpiration, passportExpiration);
    });

    test('copyWithメソッドで必須パラメータが正しく更新される', () {
      // Arrange
      final originalDto = MemberDto(id: 'member-123', displayName: '元の名前');

      // Act
      final copiedDto = originalDto.copyWith(
        id: 'member-999',
        displayName: '新しい名前',
      );

      // Assert
      expect(copiedDto.id, 'member-999');
      expect(copiedDto.displayName, '新しい名前');
    });

    test('copyWithメソッドでオプショナルパラメータが正しく更新される', () {
      // Arrange
      final originalDto = MemberDto(
        id: 'member-123',
        displayName: '山田太郎',
        email: 'old@example.com',
        phoneNumber: '090-1111-1111',
        type: 'adult',
      );

      // Act
      final copiedDto = originalDto.copyWith(
        email: 'new@example.com',
        phoneNumber: '090-9999-9999',
        type: 'child',
      );

      // Assert
      expect(copiedDto.id, 'member-123');
      expect(copiedDto.displayName, '山田太郎');
      expect(copiedDto.email, 'new@example.com');
      expect(copiedDto.phoneNumber, '090-9999-9999');
      expect(copiedDto.type, 'child');
    });

    test('copyWithメソッドでnullを指定しても元の値が保持される', () {
      // Arrange
      final birthday = DateTime(1990, 1, 1);
      final originalDto = MemberDto(
        id: 'member-123',
        accountId: 'account-456',
        ownerId: 'owner-789',
        displayName: '山田太郎',
        email: 'yamada@example.com',
        phoneNumber: '090-1234-5678',
        birthday: birthday,
        gender: 'male',
        type: 'adult',
      );

      // Act
      final copiedDto = originalDto.copyWith();

      // Assert
      expect(copiedDto.id, 'member-123');
      expect(copiedDto.accountId, 'account-456');
      expect(copiedDto.ownerId, 'owner-789');
      expect(copiedDto.displayName, '山田太郎');
      expect(copiedDto.email, 'yamada@example.com');
      expect(copiedDto.phoneNumber, '090-1234-5678');
      expect(copiedDto.birthday, birthday);
      expect(copiedDto.gender, 'male');
      expect(copiedDto.type, 'adult');
    });

    test('同じ値を持つインスタンスは等しい', () {
      // Arrange
      const id = 'member-123';
      const accountId = 'account-456';
      const displayName = '山田太郎';
      const email = 'yamada@example.com';
      final birthday = DateTime(1990, 1, 1);
      const type = 'adult';

      final dto1 = MemberDto(
        id: id,
        accountId: accountId,
        displayName: displayName,
        email: email,
        birthday: birthday,
        type: type,
      );

      final dto2 = MemberDto(
        id: id,
        accountId: accountId,
        displayName: displayName,
        email: email,
        birthday: birthday,
        type: type,
      );

      // Act & Assert
      expect(dto1, equals(dto2));
      expect(dto1.hashCode, equals(dto2.hashCode));
    });

    test('異なる値を持つインスタンスは等しくない', () {
      // Arrange
      final dto1 = MemberDto(
        id: 'member-123',
        accountId: 'account-456',
        displayName: '山田太郎',
        email: 'yamada@example.com',
        type: 'adult',
      );

      final dto2 = MemberDto(
        id: 'member-999',
        accountId: 'account-888',
        displayName: '田中花子',
        email: 'tanaka@example.com',
        type: 'child',
      );

      // Act & Assert
      expect(dto1, isNot(equals(dto2)));
      expect(dto1.hashCode, isNot(equals(dto2.hashCode)));
    });

    test('日本語名のみを持つメンバーを作成できる', () {
      // Arrange
      const id = 'member-123';
      const hiraganaFirstName = 'たろう';
      const hiraganaLastName = 'やまだ';
      const kanjiFirstName = '太郎';
      const kanjiLastName = '山田';
      const displayName = '山田太郎';

      // Act
      final dto = MemberDto(
        id: id,
        hiraganaFirstName: hiraganaFirstName,
        hiraganaLastName: hiraganaLastName,
        kanjiFirstName: kanjiFirstName,
        kanjiLastName: kanjiLastName,
        displayName: displayName,
      );

      // Assert
      expect(dto.hiraganaFirstName, hiraganaFirstName);
      expect(dto.hiraganaLastName, hiraganaLastName);
      expect(dto.kanjiFirstName, kanjiFirstName);
      expect(dto.kanjiLastName, kanjiLastName);
      expect(dto.firstName, isNull);
      expect(dto.lastName, isNull);
    });

    test('英語名のみを持つメンバーを作成できる', () {
      // Arrange
      const id = 'member-123';
      const firstName = 'John';
      const lastName = 'Doe';
      const displayName = 'John Doe';

      // Act
      final dto = MemberDto(
        id: id,
        firstName: firstName,
        lastName: lastName,
        displayName: displayName,
      );

      // Assert
      expect(dto.firstName, firstName);
      expect(dto.lastName, lastName);
      expect(dto.hiraganaFirstName, isNull);
      expect(dto.hiraganaLastName, isNull);
      expect(dto.kanjiFirstName, isNull);
      expect(dto.kanjiLastName, isNull);
    });

    test('パスポート情報を持つメンバーを作成できる', () {
      // Arrange
      const id = 'member-123';
      const displayName = '山田太郎';
      const passportNumber = 'AB1234567';
      const passportExpiration = '2030-12-31';

      // Act
      final dto = MemberDto(
        id: id,
        displayName: displayName,
        passportNumber: passportNumber,
        passportExpiration: passportExpiration,
      );

      // Assert
      expect(dto.passportNumber, passportNumber);
      expect(dto.passportExpiration, passportExpiration);
    });
  });
}
