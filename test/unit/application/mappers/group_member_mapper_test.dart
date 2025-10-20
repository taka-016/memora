import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/mappers/group_member_mapper.dart';
import 'package:memora/domain/entities/member.dart';

void main() {
  group('GroupMemberMapper', () {
    group('fromMember', () {
      test('MemberをGroupMemberDtoに変換できる', () {
        // Arrange
        const member = Member(
          id: 'member1',
          accountId: 'account1',
          ownerId: 'owner1',
          displayName: '山田太郎',
          hiraganaFirstName: 'たろう',
          hiraganaLastName: 'やまだ',
          kanjiFirstName: '太郎',
          kanjiLastName: '山田',
          firstName: 'Taro',
          lastName: 'Yamada',
          type: 'adult',
          birthday: null,
          gender: 'male',
          email: 'taro@example.com',
          phoneNumber: '090-1234-5678',
          passportNumber: 'AB1234567',
          passportExpiration: '2030-12-31',
        );
        const groupId = 'group1';

        // Act
        final result = GroupMemberMapper.fromMember(member, groupId);

        // Assert
        expect(result.memberId, 'member1');
        expect(result.groupId, 'group1');
        expect(result.isAdministrator, false);
        expect(result.accountId, 'account1');
        expect(result.ownerId, 'owner1');
        expect(result.displayName, '山田太郎');
        expect(result.hiraganaFirstName, 'たろう');
        expect(result.hiraganaLastName, 'やまだ');
        expect(result.kanjiFirstName, '太郎');
        expect(result.kanjiLastName, '山田');
        expect(result.firstName, 'Taro');
        expect(result.lastName, 'Yamada');
        expect(result.type, 'adult');
        expect(result.birthday, null);
        expect(result.gender, 'male');
        expect(result.email, 'taro@example.com');
        expect(result.phoneNumber, '090-1234-5678');
        expect(result.passportNumber, 'AB1234567');
        expect(result.passportExpiration, '2030-12-31');
      });

      test('最小限のフィールドのみ持つMemberを変換できる', () {
        // Arrange
        const member = Member(id: 'member2', displayName: '佐藤花子');
        const groupId = 'group2';

        // Act
        final result = GroupMemberMapper.fromMember(member, groupId);

        // Assert
        expect(result.memberId, 'member2');
        expect(result.groupId, 'group2');
        expect(result.isAdministrator, false);
        expect(result.displayName, '佐藤花子');
        expect(result.accountId, null);
        expect(result.ownerId, null);
        expect(result.hiraganaFirstName, null);
        expect(result.hiraganaLastName, null);
      });
    });

    group('fromMemberList', () {
      test('MemberのリストをGroupMemberDtoのリストに変換できる', () {
        // Arrange
        const members = [
          Member(id: 'member1', displayName: '山田太郎', email: 'taro@example.com'),
          Member(
            id: 'member2',
            displayName: '佐藤花子',
            email: 'hanako@example.com',
          ),
          Member(id: 'member3', displayName: '鈴木一郎'),
        ];
        const groupId = 'group1';

        // Act
        final result = GroupMemberMapper.fromMemberList(members, groupId);

        // Assert
        expect(result.length, 3);
        expect(result[0].memberId, 'member1');
        expect(result[0].groupId, 'group1');
        expect(result[0].displayName, '山田太郎');
        expect(result[0].email, 'taro@example.com');
        expect(result[1].memberId, 'member2');
        expect(result[1].groupId, 'group1');
        expect(result[1].displayName, '佐藤花子');
        expect(result[1].email, 'hanako@example.com');
        expect(result[2].memberId, 'member3');
        expect(result[2].groupId, 'group1');
        expect(result[2].displayName, '鈴木一郎');
        expect(result[2].email, null);
      });

      test('空のリストを変換できる', () {
        // Arrange
        const members = <Member>[];
        const groupId = 'group1';

        // Act
        final result = GroupMemberMapper.fromMemberList(members, groupId);

        // Assert
        expect(result, isEmpty);
      });
    });
  });
}
