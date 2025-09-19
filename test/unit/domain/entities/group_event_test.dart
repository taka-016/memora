import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/group_event.dart';

void main() {
  group('GroupEvent', () {
    test('インスタンス生成が正しく行われる', () {
      final now = DateTime.now();
      final event = GroupEvent(
        id: 'event001',
        groupId: 'group001',
        type: 'typeA',
        name: 'イベント名',
        startDate: now,
        endDate: now,
        memo: 'メモ',
      );
      expect(event.id, 'event001');
      expect(event.groupId, 'group001');
      expect(event.type, 'typeA');
      expect(event.name, 'イベント名');
      expect(event.startDate, now);
      expect(event.endDate, now);
      expect(event.memo, 'メモ');
    });

    test('nullableなフィールドがnullの場合でもインスタンス生成が正しく行われる', () {
      final now = DateTime.now();
      final event = GroupEvent(
        id: 'event001',
        groupId: 'group001',
        type: 'typeA',
        startDate: now,
        endDate: now,
      );
      expect(event.id, 'event001');
      expect(event.groupId, 'group001');
      expect(event.type, 'typeA');
      expect(event.name, null);
      expect(event.startDate, now);
      expect(event.endDate, now);
      expect(event.memo, null);
    });

    test('同じプロパティを持つインスタンス同士は等価である', () {
      final now = DateTime.now();
      final event1 = GroupEvent(
        id: 'event001',
        groupId: 'group001',
        type: 'typeA',
        name: 'イベント名',
        startDate: now,
        endDate: now,
        memo: 'メモ',
      );
      final event2 = GroupEvent(
        id: 'event001',
        groupId: 'group001',
        type: 'typeA',
        name: 'イベント名',
        startDate: now,
        endDate: now,
        memo: 'メモ',
      );
      expect(event1, equals(event2));
    });

    test('copyWithメソッドが正しく動作する', () {
      final now = DateTime.now();
      final later = now.add(const Duration(hours: 1));
      final event = GroupEvent(
        id: 'event001',
        groupId: 'group001',
        type: 'typeA',
        name: 'イベント名',
        startDate: now,
        endDate: now,
        memo: 'メモ',
      );
      final updatedEvent = event.copyWith(name: '新しいイベント名', endDate: later);
      expect(updatedEvent.id, 'event001');
      expect(updatedEvent.groupId, 'group001');
      expect(updatedEvent.type, 'typeA');
      expect(updatedEvent.name, '新しいイベント名');
      expect(updatedEvent.startDate, now);
      expect(updatedEvent.endDate, later);
      expect(updatedEvent.memo, 'メモ');
    });
  });
}
