import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/mappers/group/group_mapper.dart';
import 'package:memora/infrastructure/mappers/group/sqlite_group_mapper.dart';
import 'package:memora/infrastructure/mappers/group/sqlite_group_member_mapper.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_mapper.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_member_mapper.dart';

void main() {
  test('グループと所属の色を別々に保存し編集後も保持する', () {
    const dto = GroupDto(
      id: 'g',
      ownerId: 'm',
      name: '家族',
      color: '#123456',
      members: [
        GroupMemberDto(
          groupId: 'g',
          memberId: 'm',
          displayName: '太郎',
          color: '#ABCDEF',
        ),
      ],
    );
    final entity = GroupMapper.toEntity(dto.copyWith(name: '親戚'));
    expect(SqliteGroupMapper.toRow(entity)['color'], '#123456');
    expect(
      SqliteGroupMemberMapper.toRow(
        entity.members.single.copyWith(orderIndex: 2),
      )['color'],
      '#ABCDEF',
    );
    expect(FirestoreGroupMapper.toCreateFirestore(entity)['color'], '#123456');
    expect(
      FirestoreGroupMemberMapper.toCreateFirestore(
        entity.members.single,
      )['color'],
      '#ABCDEF',
    );
    expect(dto.copyWith(color: '#FFFFFF'), isNot(dto));
    expect(
      dto.members.single.copyWith(color: '#000000'),
      isNot(dto.members.single),
    );
  });
}
