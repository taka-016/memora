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
      textColor: '#FFFFFF',
      members: [
        GroupMemberDto(
          groupId: 'g',
          memberId: 'm',
          displayName: '太郎',
          color: '#ABCDEF',
          textColor: '#000000',
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
    expect(SqliteGroupMapper.toRow(entity)['text_color'], '#FFFFFF');
    expect(SqliteGroupMemberMapper.toRow(entity.members.single.copyWith(orderIndex: 2))['text_color'], '#000000');
    expect(FirestoreGroupMapper.toUpdateFirestore(entity)['textColor'], '#FFFFFF');
    expect(FirestoreGroupMemberMapper.toCreateFirestore(entity.members.single)['textColor'], '#000000');
    expect(GroupMapper.toEntity(dto.copyWith(textColor: null)).textColor, isNull);
    expect(entity.copyWith(textColor: null).textColor, isNull);
    expect(entity.members.single.copyWith(textColor: null).textColor, isNull);
    expect(dto.copyWith(color: '#FFFFFF'), isNot(dto));
    expect(
      dto.members.single.copyWith(color: '#000000'),
      isNot(dto.members.single),
    );
  });
}
