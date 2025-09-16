import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/mappers/group_mapper.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/group_member.dart';
import 'package:memora/domain/entities/group_event.dart';

void main() {
  group('GroupMapper', () {
    group('toDto', () {
      test('GroupエンティティをGroupDtoに正しく変換する', () {
        // Arrange
        final groupMembers = [
          GroupMember(
            id: 'member-1',
            groupId: 'group-1',
            memberId: 'member-id-1',
          ),
        ];

        final groupEvents = [
          GroupEvent(
            id: 'event-1',
            groupId: 'group-1',
            type: 'テストイベント',
            name: 'イベント名',
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 2),
            memo: 'イベントメモ',
          ),
        ];

        final group = Group(
          id: 'group-1',
          ownerId: 'owner-1',
          name: 'テストグループ',
          memo: 'テストメモ',
          members: groupMembers,
          events: groupEvents,
        );

        // Act
        final dto = GroupMapper.toDto(group);

        // Assert
        expect(dto.ownerId, 'owner-1');
        expect(dto.name, 'テストグループ');
        expect(dto.memo, 'テストメモ');
        expect(dto.members.length, 1);
        expect(dto.members.first.groupId, 'group-1');
        expect(dto.events.length, 1);
        expect(dto.events.first.groupId, 'group-1');
      });

      test('membersがnullの場合は空のリストに変換される', () {
        // Arrange
        final group = Group(
          id: 'group-1',
          ownerId: 'owner-1',
          name: 'テストグループ',
          members: null,
          events: null,
        );

        // Act
        final dto = GroupMapper.toDto(group);

        // Assert
        expect(dto.members, isEmpty);
        expect(dto.events, isEmpty);
      });
    });

    group('toEntity', () {
      test('GroupDtoをGroupエンティティに正しく変換する', () {
        // Arrange
        final groupMemberDtos = [
          GroupMemberDto(groupId: 'group-1', memberId: 'member-id-1'),
        ];

        final groupEventDtos = [
          GroupEventDto(
            groupId: 'group-1',
            type: 'テストイベント',
            name: 'イベント名',
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 2),
            memo: 'イベントメモ',
          ),
        ];

        final dto = GroupDto(
          ownerId: 'owner-1',
          name: 'テストグループ',
          memo: 'テストメモ',
          members: groupMemberDtos,
          events: groupEventDtos,
        );

        // Act
        final entity = GroupMapper.toEntity(dto, id: 'group-1');

        // Assert
        expect(entity.id, 'group-1');
        expect(entity.ownerId, 'owner-1');
        expect(entity.name, 'テストグループ');
        expect(entity.memo, 'テストメモ');
        expect(entity.members?.length, 1);
        expect(entity.members?.first.groupId, 'group-1');
        expect(entity.events?.length, 1);
        expect(entity.events?.first.groupId, 'group-1');
      });
    });

    group('toDtoList', () {
      test('Groupエンティティリストを正しく変換する', () {
        // Arrange
        final groups = [
          Group(id: 'group-1', ownerId: 'owner-1', name: 'グループ1'),
          Group(id: 'group-2', ownerId: 'owner-1', name: 'グループ2'),
        ];

        // Act
        final dtos = GroupMapper.toDtoList(groups);

        // Assert
        expect(dtos.length, 2);
        expect(dtos[0].ownerId, 'owner-1');
        expect(dtos[0].name, 'グループ1');
        expect(dtos[1].ownerId, 'owner-1');
        expect(dtos[1].name, 'グループ2');
      });
    });

    group('toEntityList', () {
      test('GroupDtoリストを正しく変換する', () {
        // Arrange
        final dtos = [
          GroupDto(ownerId: 'owner-1', name: 'グループ1'),
          GroupDto(ownerId: 'owner-1', name: 'グループ2'),
        ];

        // Act
        final entities = GroupMapper.toEntityList(
          dtos,
          ids: ['group-1', 'group-2'],
        );

        // Assert
        expect(entities.length, 2);
        expect(entities[0].id, 'group-1');
        expect(entities[0].name, 'グループ1');
        expect(entities[1].id, 'group-2');
        expect(entities[1].name, 'グループ2');
      });
    });
  });
}
