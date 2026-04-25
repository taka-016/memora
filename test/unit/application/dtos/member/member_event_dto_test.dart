import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_event_dto.dart';

void main() {
  group('MemberEventDto', () {
    test('ER図どおりの項目で生成できる', () {
      const dto = MemberEventDto(
        id: 'member-event-123',
        memberId: 'member-456',
        year: 2026,
        memo: '入学式',
      );

      expect(dto.id, 'member-event-123');
      expect(dto.memberId, 'member-456');
      expect(dto.year, 2026);
      expect(dto.memo, '入学式');
    });

    test('copyWithで年表セル単位の値を更新できる', () {
      const originalDto = MemberEventDto(
        id: 'member-event-123',
        memberId: 'member-456',
        year: 2026,
        memo: '入学式',
      );

      final copiedDto = originalDto.copyWith(
        id: 'member-event-999',
        memberId: 'member-888',
        year: 2027,
        memo: '卒業式',
      );

      expect(copiedDto.id, 'member-event-999');
      expect(copiedDto.memberId, 'member-888');
      expect(copiedDto.year, 2027);
      expect(copiedDto.memo, '卒業式');
    });

    test('同じ値を持つインスタンスは等しい', () {
      const dto1 = MemberEventDto(
        id: 'member-event-123',
        memberId: 'member-456',
        year: 2026,
        memo: '入学式',
      );
      const dto2 = MemberEventDto(
        id: 'member-event-123',
        memberId: 'member-456',
        year: 2026,
        memo: '入学式',
      );

      expect(dto1, dto2);
      expect(dto1.hashCode, dto2.hashCode);
    });
  });
}
