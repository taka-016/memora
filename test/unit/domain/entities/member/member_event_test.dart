import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/member/member_event.dart';

void main() {
  group('MemberEvent', () {
    test('ER図どおりの項目でインスタンス生成できる', () {
      const event = MemberEvent(
        id: 'event001',
        memberId: 'member001',
        year: 2026,
        memo: '入学式',
      );

      expect(event.id, 'event001');
      expect(event.memberId, 'member001');
      expect(event.year, 2026);
      expect(event.memo, '入学式');
    });

    test('同じプロパティを持つインスタンス同士は等価である', () {
      const event1 = MemberEvent(
        id: 'event001',
        memberId: 'member001',
        year: 2026,
        memo: '入学式',
      );
      const event2 = MemberEvent(
        id: 'event001',
        memberId: 'member001',
        year: 2026,
        memo: '入学式',
      );

      expect(event1, event2);
    });

    test('copyWithで年表セル単位の値を更新できる', () {
      const event = MemberEvent(
        id: 'event001',
        memberId: 'member001',
        year: 2026,
        memo: '入学式',
      );

      final updatedEvent = event.copyWith(year: 2027, memo: '卒業式');

      expect(updatedEvent.id, 'event001');
      expect(updatedEvent.memberId, 'member001');
      expect(updatedEvent.year, 2027);
      expect(updatedEvent.memo, '卒業式');
    });
  });
}
