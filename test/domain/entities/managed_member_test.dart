import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/managed_member.dart';

void main() {
  group('ManagedMember', () {
    test('インスタンス生成が正しく行われる', () {
      final managedMember = ManagedMember(
        id: 'mm001',
        memberId: 'member001',
        managedMemberId: 'member002',
      );
      expect(managedMember.id, 'mm001');
      expect(managedMember.memberId, 'member001');
      expect(managedMember.managedMemberId, 'member002');
    });
  });
}