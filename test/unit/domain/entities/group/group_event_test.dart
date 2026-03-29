import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/group/group_event.dart';

void main() {
  group('GroupEvent', () {
    test('インスタンス生成が正しく行われる', () {
      const event = GroupEvent(
        id: 'event001',
        groupId: 'group001',
        year: 2025,
        memo: '家族旅行の計画を立てる',
      );

      expect(event.id, 'event001');
      expect(event.groupId, 'group001');
      expect(event.year, 2025);
      expect(event.memo, '家族旅行の計画を立てる');
    });

    test('同じプロパティを持つインスタンス同士は等価である', () {
      const event1 = GroupEvent(
        id: 'event001',
        groupId: 'group001',
        year: 2025,
        memo: '運動会',
      );
      const event2 = GroupEvent(
        id: 'event001',
        groupId: 'group001',
        year: 2025,
        memo: '運動会',
      );

      expect(event1, equals(event2));
    });

    test('copyWithメソッドが正しく動作する', () {
      const event = GroupEvent(
        id: 'event001',
        groupId: 'group001',
        year: 2025,
        memo: '運動会',
      );

      final updatedEvent = event.copyWith(year: 2026, memo: '修学旅行');

      expect(updatedEvent.id, 'event001');
      expect(updatedEvent.groupId, 'group001');
      expect(updatedEvent.year, 2026);
      expect(updatedEvent.memo, '修学旅行');
    });
  });
}
