import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/calendar/calendar_label.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

void main() {
  CalendarLabel label({
    String name = '家族全員',
    String color = '#12aBcD',
    String groupId = 'group',
  }) => CalendarLabel(id: 'label', groupId: groupId, name: name, color: color);

  test('共通ラベルの名前と色を変更できる', () {
    final changed = label().copyWith(name: '子供', color: '#FF0000');
    expect(changed.name, '子供');
    expect(changed.color, '#FF0000');
    expect(changed.groupId, 'group');
  });
  for (final name in ['', '  ']) {
    test('空のラベル名「$name」を拒否する', () {
      expect(() => label(name: name), throwsA(isA<ValidationException>()));
    });
  }
  for (final color in ['', 'red', '#12345', '#GG0000', '#12345678']) {
    test('不正な色「$color」を拒否する', () {
      expect(() => label(color: color), throwsA(isA<ValidationException>()));
    });
  }
  test('グループのないラベルと不正な更新を拒否する', () {
    expect(() => label(groupId: ''), throwsA(isA<ValidationException>()));
    expect(
      () => label().copyWith(name: ''),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => label().copyWith(color: ''),
      throwsA(isA<ValidationException>()),
    );
  });
}
