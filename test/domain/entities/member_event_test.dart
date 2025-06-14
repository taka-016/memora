import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/member_event.dart';

void main() {
  group('MemberEvent', () {
    test('インスタンス生成が正しく行われる', () {
      final now = DateTime.now();
      final event = MemberEvent(
        id: 'event001',
        memberId: 'member001',
        type: 'typeA',
        name: 'イベント名',
        startDate: now,
        endDate: now,
        memo: 'メモ',
      );
      expect(event.id, 'event001');
      expect(event.memberId, 'member001');
      expect(event.type, 'typeA');
      expect(event.name, 'イベント名');
      expect(event.startDate, now);
      expect(event.endDate, now);
      expect(event.memo, 'メモ');
    });
  });
}
