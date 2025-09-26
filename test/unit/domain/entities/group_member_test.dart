import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/group_member.dart';

void main() {
  group('GroupMember', () {
    test('インスタンス生成が正しく行われる', () {
      final member = GroupMember(groupId: 'group001', memberId: 'member001');
      expect(member.groupId, 'group001');
      expect(member.memberId, 'member001');
      expect(member.isAdministrator, false);
    });

    test('同じプロパティを持つインスタンス同士は等価である', () {
      final member1 = GroupMember(
        groupId: 'group001',
        memberId: 'member001',
        isAdministrator: true,
      );
      final member2 = GroupMember(
        groupId: 'group001',
        memberId: 'member001',
        isAdministrator: true,
      );
      expect(member1, equals(member2));
    });

    test('異なるプロパティを持つインスタンス同士は等価でない', () {
      final member1 = GroupMember(groupId: 'group001', memberId: 'member001');
      final member2 = GroupMember(groupId: 'group002', memberId: 'member001');
      expect(member1, isNot(equals(member2)));
    });

    test('copyWithメソッドが正しく動作する', () {
      final member = GroupMember(
        groupId: 'group001',
        memberId: 'member001',
        isAdministrator: false,
      );
      final updatedMember = member.copyWith(
        groupId: 'group002',
        memberId: 'member002',
        isAdministrator: true,
      );
      expect(updatedMember.groupId, 'group002');
      expect(updatedMember.memberId, 'member002');
      expect(updatedMember.isAdministrator, true);
    });
  });
}
