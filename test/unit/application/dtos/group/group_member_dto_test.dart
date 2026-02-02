import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';

void main() {
  group('GroupMemberDto', () {
    test('必須パラメータでコンストラクタが正しく動作する', () {
      // Arrange
      const memberId = 'member-123';
      const groupId = 'group-456';
      const displayName = '山田太郎';

      // Act
      final dto = GroupMemberDto(
        memberId: memberId,
        groupId: groupId,
        displayName: displayName,
      );

      // Assert
      expect(dto.memberId, memberId);
      expect(dto.groupId, groupId);
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
      expect(dto.isAdministrator, false);
      expect(dto.orderIndex, 0);
    });

    test('全パラメータでコンストラクタが正しく動作する', () {
      // Arrange
      const memberId = 'member-123';
      const groupId = 'group-456';
      const accountId = 'account-789';
      const ownerId = 'owner-012';
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
      const isAdministrator = true;
      const orderIndex = 2;

      // Act
      final dto = GroupMemberDto(
        memberId: memberId,
        groupId: groupId,
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
        isAdministrator: isAdministrator,
        orderIndex: orderIndex,
      );

      // Assert
      expect(dto.memberId, memberId);
      expect(dto.groupId, groupId);
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
      expect(dto.isAdministrator, isAdministrator);
      expect(dto.orderIndex, orderIndex);
    });

    test('copyWithメソッドで必須パラメータが正しく更新される', () {
      // Arrange
      final originalDto = GroupMemberDto(
        memberId: 'member-123',
        groupId: 'group-456',
        displayName: '元の名前',
      );

      // Act
      final copiedDto = originalDto.copyWith(
        memberId: 'member-999',
        groupId: 'group-888',
        displayName: '新しい名前',
        orderIndex: 1,
      );

      // Assert
      expect(copiedDto.memberId, 'member-999');
      expect(copiedDto.groupId, 'group-888');
      expect(copiedDto.displayName, '新しい名前');
      expect(copiedDto.orderIndex, 1);
    });

    test('copyWithメソッドでオプショナルパラメータが正しく更新される', () {
      // Arrange
      final originalDto = GroupMemberDto(
        memberId: 'member-123',
        groupId: 'group-456',
        displayName: '山田太郎',
        email: 'old@example.com',
        phoneNumber: '090-1111-1111',
        isAdministrator: false,
      );

      // Act
      final copiedDto = originalDto.copyWith(
        email: 'new@example.com',
        phoneNumber: '090-9999-9999',
        isAdministrator: true,
        orderIndex: 3,
      );

      // Assert
      expect(copiedDto.memberId, 'member-123');
      expect(copiedDto.groupId, 'group-456');
      expect(copiedDto.displayName, '山田太郎');
      expect(copiedDto.email, 'new@example.com');
      expect(copiedDto.phoneNumber, '090-9999-9999');
      expect(copiedDto.isAdministrator, true);
      expect(copiedDto.orderIndex, 3);
    });

    test('copyWithメソッドでnullを指定しても元の値が保持される', () {
      // Arrange
      final birthday = DateTime(1990, 1, 1);
      final originalDto = GroupMemberDto(
        memberId: 'member-123',
        groupId: 'group-456',
        accountId: 'account-789',
        displayName: '山田太郎',
        email: 'yamada@example.com',
        phoneNumber: '090-1234-5678',
        birthday: birthday,
        isAdministrator: true,
      );

      // Act
      final copiedDto = originalDto.copyWith();

      // Assert
      expect(copiedDto.memberId, 'member-123');
      expect(copiedDto.groupId, 'group-456');
      expect(copiedDto.accountId, 'account-789');
      expect(copiedDto.displayName, '山田太郎');
      expect(copiedDto.email, 'yamada@example.com');
      expect(copiedDto.phoneNumber, '090-1234-5678');
      expect(copiedDto.birthday, birthday);
      expect(copiedDto.isAdministrator, true);
      expect(copiedDto.orderIndex, 0);
    });

    test('同じ値を持つインスタンスは等しい', () {
      // Arrange
      const memberId = 'member-123';
      const groupId = 'group-456';
      const displayName = '山田太郎';
      const email = 'yamada@example.com';
      final birthday = DateTime(1990, 1, 1);

      final dto1 = GroupMemberDto(
        memberId: memberId,
        groupId: groupId,
        displayName: displayName,
        email: email,
        birthday: birthday,
        isAdministrator: true,
        orderIndex: 0,
      );

      final dto2 = GroupMemberDto(
        memberId: memberId,
        groupId: groupId,
        displayName: displayName,
        email: email,
        birthday: birthday,
        isAdministrator: true,
        orderIndex: 0,
      );

      // Act & Assert
      expect(dto1, equals(dto2));
      expect(dto1.hashCode, equals(dto2.hashCode));
    });

    test('異なる値を持つインスタンスは等しくない', () {
      // Arrange
      final dto1 = GroupMemberDto(
        memberId: 'member-123',
        groupId: 'group-456',
        displayName: '山田太郎',
        email: 'yamada@example.com',
        isAdministrator: true,
        orderIndex: 0,
      );

      final dto2 = GroupMemberDto(
        memberId: 'member-999',
        groupId: 'group-888',
        displayName: '田中花子',
        email: 'tanaka@example.com',
        isAdministrator: false,
        orderIndex: 1,
      );

      // Act & Assert
      expect(dto1, isNot(equals(dto2)));
      expect(dto1.hashCode, isNot(equals(dto2.hashCode)));
    });

    test('isAdministratorのデフォルト値はfalseである', () {
      // Arrange & Act
      final dto = GroupMemberDto(
        memberId: 'member-123',
        groupId: 'group-456',
        displayName: '山田太郎',
      );

      // Assert
      expect(dto.isAdministrator, false);
    });
  });
}
