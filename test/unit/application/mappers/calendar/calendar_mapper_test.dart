import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/mappers/calendar/calendar_event_mapper.dart';
import 'package:memora/application/mappers/calendar/calendar_label_mapper.dart';

void main() {
  test('予定を変換してもグループ・ラベル・タイトル・終日区分・月をまたぐ期間を保持する', () {
    final dto = CalendarEventDto(
      id: 'event',
      groupId: 'group',
      labelId: 'label',
      title: '家族旅行',
      startDateTime: DateTime(2026, 10, 31),
      endDateTime: DateTime(2026, 11, 2),
      isAllDay: true,
    );
    final entity = CalendarEventMapper.toEntity(dto);
    expect(entity.groupId, dto.groupId);
    expect(entity.labelId, dto.labelId);
    expect(entity.title, dto.title);
    expect(entity.startDateTime, dto.startDateTime);
    expect(entity.endDateTime, dto.endDateTime);
    expect(entity.isAllDay, dto.isAllDay);
    expect(CalendarEventMapper.toDto(entity), dto);
  });
  test('ラベルの変換でグループと名前・色を保持する', () {
    const dto = CalendarLabelDto(
      id: 'label',
      groupId: 'group',
      name: '家族全員',
      color: '#123ABC',
      textColor: '#A1b2C3',
      sortOrder: 3,
    );
    final entity = CalendarLabelMapper.toEntity(dto);
    expect(entity.groupId, dto.groupId);
    expect(entity.name, dto.name);
    expect(entity.color, dto.color);
    expect(entity.textColor, dto.textColor);
    expect(entity.sortOrder, 3);
    expect(dto.copyWith(textColor: '#000000').textColor, '#000000');
    expect(dto.copyWith(textColor: '#000000'), isNot(dto));
    expect(CalendarLabelMapper.toDto(entity), dto);
  });
}
