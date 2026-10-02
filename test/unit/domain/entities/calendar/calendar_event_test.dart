import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/calendar/calendar_event.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

void main() {
  final start = DateTime(2026, 10, 2, 10);
  CalendarEvent event({
    String title = '家族の予定',
    String groupId = 'group',
    String labelId = 'label',
    DateTime? end,
    bool isAllDay = false,
  }) => CalendarEvent(
    id: 'event',
    groupId: groupId,
    labelId: labelId,
    title: title,
    startDateTime: start,
    endDateTime: end ?? start,
    isAllDay: isAllDay,
  );

  test('開始と終了が同じ日時の予定を許可する', () {
    expect(event().endDateTime, start);
  });
  test('終日で複数日にわたる予定の期間を保持する', () {
    final end = DateTime(2026, 10, 5);
    final result = event(end: end, isAllDay: true);
    expect(result.startDateTime, start);
    expect(result.endDateTime, end);
    expect(result.isAllDay, isTrue);
  });
  for (final title in ['', '  ', '\n\t']) {
    test('空白だけのタイトル「$title」を拒否する', () {
      expect(() => event(title: title), throwsA(isA<ValidationException>()));
    });
  }
  test('終了日時が開始日時より前の予定を拒否する', () {
    expect(
      () => event(end: start.subtract(const Duration(microseconds: 1))),
      throwsA(isA<ValidationException>()),
    );
  });
  test('グループまたはラベルの指定がない予定を拒否する', () {
    expect(() => event(groupId: ' '), throwsA(isA<ValidationException>()));
    expect(() => event(labelId: ''), throwsA(isA<ValidationException>()));
  });
  test('更新でもタイトルと期間の制約を維持する', () {
    expect(
      () => event().copyWith(title: ''),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => event().copyWith(endDateTime: DateTime(2026, 10, 1)),
      throwsA(isA<ValidationException>()),
    );
  });
}
