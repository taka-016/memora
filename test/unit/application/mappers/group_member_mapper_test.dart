import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/mappers/group_member_mapper.dart';
import 'package:memora/domain/entities/group_member.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'group_member_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('GroupMemberMapper', () {
    group('fromFirestore', () {
      test('FirestoreのDocumentSnapshotからGroupMemberDtoへ変換できる', () {
        // Arrange
        final mockGroupMemberDoc = MockDocumentSnapshot<Map<String, dynamic>>();
        final mockMemberDoc = MockDocumentSnapshot<Map<String, dynamic>>();

        when(mockMemberDoc.id).thenReturn('member001');
        when(
          mockGroupMemberDoc.data(),
        ).thenReturn({'groupId': 'group001', 'isAdministrator': true});
        when(mockMemberDoc.data()).thenReturn({
          'accountId': 'account001',
          'ownerId': 'owner001',
          'displayName': '山田太郎',
          'hiraganaFirstName': 'たろう',
          'hiraganaLastName': 'やまだ',
          'kanjiFirstName': '太郎',
          'kanjiLastName': '山田',
          'firstName': 'Taro',
          'lastName': 'Yamada',
          'type': 'adult',
          'birthday': Timestamp.fromDate(DateTime(1990, 1, 1)),
          'gender': 'male',
          'email': 'taro@example.com',
          'phoneNumber': '090-1234-5678',
          'passportNumber': 'AB1234567',
          'passportExpiration': '2030-12-31',
        });

        // Act
        final result = GroupMemberMapper.fromFirestore(
          mockGroupMemberDoc,
          mockMemberDoc,
        );

        // Assert
        expect(result.memberId, 'member001');
        expect(result.groupId, 'group001');
        expect(result.isAdministrator, true);
        expect(result.accountId, 'account001');
        expect(result.ownerId, 'owner001');
        expect(result.displayName, '山田太郎');
        expect(result.hiraganaFirstName, 'たろう');
        expect(result.hiraganaLastName, 'やまだ');
        expect(result.kanjiFirstName, '太郎');
        expect(result.kanjiLastName, '山田');
        expect(result.firstName, 'Taro');
        expect(result.lastName, 'Yamada');
        expect(result.type, 'adult');
        expect(result.birthday, DateTime(1990, 1, 1));
        expect(result.gender, 'male');
        expect(result.email, 'taro@example.com');
        expect(result.phoneNumber, '090-1234-5678');
        expect(result.passportNumber, 'AB1234567');
        expect(result.passportExpiration, '2030-12-31');
      });

      test('isAdministratorが未設定の場合はfalseになる', () {
        // Arrange
        final mockGroupMemberDoc = MockDocumentSnapshot<Map<String, dynamic>>();
        final mockMemberDoc = MockDocumentSnapshot<Map<String, dynamic>>();

        when(mockMemberDoc.id).thenReturn('member002');
        when(mockGroupMemberDoc.data()).thenReturn({'groupId': 'group002'});
        when(mockMemberDoc.data()).thenReturn({'displayName': '佐藤花子'});

        // Act
        final result = GroupMemberMapper.fromFirestore(
          mockGroupMemberDoc,
          mockMemberDoc,
        );

        // Assert
        expect(result.memberId, 'member002');
        expect(result.groupId, 'group002');
        expect(result.isAdministrator, false);
        expect(result.displayName, '佐藤花子');
      });

      test('displayNameが未設定の場合は空文字列になる', () {
        // Arrange
        final mockGroupMemberDoc = MockDocumentSnapshot<Map<String, dynamic>>();
        final mockMemberDoc = MockDocumentSnapshot<Map<String, dynamic>>();

        when(mockMemberDoc.id).thenReturn('member003');
        when(
          mockGroupMemberDoc.data(),
        ).thenReturn({'groupId': 'group003', 'isAdministrator': false});
        when(mockMemberDoc.data()).thenReturn({'email': 'test@example.com'});

        // Act
        final result = GroupMemberMapper.fromFirestore(
          mockGroupMemberDoc,
          mockMemberDoc,
        );

        // Assert
        expect(result.memberId, 'member003');
        expect(result.groupId, 'group003');
        expect(result.displayName, '');
        expect(result.email, 'test@example.com');
      });
    });

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

    group('toEntity', () {
      test('DTOからGroupMemberエンティティへ変換できる', () {
        // Arrange
        const dto = GroupMemberDto(
          memberId: 'member001',
          groupId: 'group001',
          isAdministrator: true,
          displayName: '山田太郎',
          email: 'taro@example.com',
        );

        // Act
        final entity = GroupMemberMapper.toEntity(dto);

        // Assert
        expect(
          entity,
          const GroupMember(
            groupId: 'group001',
            memberId: 'member001',
            isAdministrator: true,
          ),
        );
      });

      test('isAdministratorがfalseのDTOを変換できる', () {
        // Arrange
        const dto = GroupMemberDto(
          memberId: 'member002',
          groupId: 'group002',
          isAdministrator: false,
          displayName: '佐藤花子',
        );

        // Act
        final entity = GroupMemberMapper.toEntity(dto);

        // Assert
        expect(
          entity,
          const GroupMember(
            groupId: 'group002',
            memberId: 'member002',
            isAdministrator: false,
          ),
        );
      });
    });

    group('toEntityList', () {
      test('DTOリストからGroupMemberエンティティのリストへ変換できる', () {
        // Arrange
        const dtoList = [
          GroupMemberDto(
            memberId: 'member001',
            groupId: 'group001',
            isAdministrator: true,
            displayName: '山田太郎',
          ),
          GroupMemberDto(
            memberId: 'member002',
            groupId: 'group001',
            isAdministrator: false,
            displayName: '佐藤花子',
          ),
          GroupMemberDto(
            memberId: 'member003',
            groupId: 'group001',
            isAdministrator: false,
            displayName: '鈴木一郎',
          ),
        ];

        // Act
        final entities = GroupMemberMapper.toEntityList(dtoList);

        // Assert
        expect(entities.length, 3);
        expect(
          entities[0],
          const GroupMember(
            groupId: 'group001',
            memberId: 'member001',
            isAdministrator: true,
          ),
        );
        expect(
          entities[1],
          const GroupMember(
            groupId: 'group001',
            memberId: 'member002',
            isAdministrator: false,
          ),
        );
        expect(
          entities[2],
          const GroupMember(
            groupId: 'group001',
            memberId: 'member003',
            isAdministrator: false,
          ),
        );
      });

      test('空のリストを変換できる', () {
        // Arrange
        const dtoList = <GroupMemberDto>[];

        // Act
        final entities = GroupMemberMapper.toEntityList(dtoList);

        // Assert
        expect(entities, isEmpty);
      });
    });
  });
}
