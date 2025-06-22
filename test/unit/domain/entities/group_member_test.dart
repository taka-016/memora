import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/group_member.dart';

void main() {
  group('GroupMember', () {
    test('インスタンス生成が正しく行われる', () {
      final member = GroupMember(
        id: 'gm001',
        groupId: 'group001',
        memberId: 'member001',
      );
      expect(member.id, 'gm001');
      expect(member.groupId, 'group001');
      expect(member.memberId, 'member001');
    });
  });
}
