import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/group/group.dart';
import 'package:memora/domain/entities/group/group_member.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

void main() {
  group('Group', () {
    test('メンバーIDが重複している場合にエラーをスローする', () {
      expect(
        () => Group(
          id: 'group001',
          ownerId: 'admin001',
          name: 'グループ名',
          members: [
            GroupMember(groupId: 'group001', memberId: 'user001'),
            GroupMember(groupId: 'group001', memberId: 'user001'),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
