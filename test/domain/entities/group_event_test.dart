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

    test('nameとmemoがnullの場合でもインスタンス生成が正しく行われる', () {
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
  });
}
