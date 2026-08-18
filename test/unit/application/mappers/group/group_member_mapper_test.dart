import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/mappers/group/group_member_mapper.dart';
import 'package:memora/domain/entities/group/group_member.dart';

void main() {
  group('GroupMemberMapper', () {
    group('toEntity', () {
      test('DTOからGroupMemberエンティティへ変換できる', () {
        // Arrange
        const dto = GroupMemberDto(
          memberId: 'member001',
          groupId: 'group001',
          isAdministrator: true,
          displayName: '山田太郎',
          email: 'taro@example.com',
          orderIndex: 1,
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
            orderIndex: 1,
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
          orderIndex: 0,
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
            orderIndex: 0,
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
            orderIndex: 0,
          ),
          GroupMemberDto(
            memberId: 'member002',
            groupId: 'group001',
            isAdministrator: false,
            displayName: '佐藤花子',
            orderIndex: 1,
          ),
          GroupMemberDto(
            memberId: 'member003',
            groupId: 'group001',
            isAdministrator: false,
            displayName: '鈴木一郎',
            orderIndex: 2,
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
            orderIndex: 0,
          ),
        );
        expect(
          entities[1],
          const GroupMember(
            groupId: 'group001',
            memberId: 'member002',
            isAdministrator: false,
            orderIndex: 1,
          ),
        );
        expect(
          entities[2],
          const GroupMember(
            groupId: 'group001',
            memberId: 'member003',
            isAdministrator: false,
            orderIndex: 2,
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
