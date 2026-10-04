import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/application/mappers/calendar/calendar_event_mapper.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_expander.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:memora/domain/entities/calendar/calendar_recurrence_rule.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/calendar/calendar_event_repository.dart';

enum CalendarChangeScope { only, following, all }

class ChangeCalendarRecurrenceUsecase {
  ChangeCalendarRecurrenceUsecase(this._repository, this._expander);
  final CalendarEventRepository _repository;
  final CalendarRecurrenceExpander _expander;

  Future<void> execute(
    CalendarEventDto source,
    DateTime original,
    CalendarChangeScope scope, {
    CalendarEventDto? changes,
  }) async {
    try {
      if (source.recurrenceRule == null ||
          source.id.isEmpty ||
          (changes != null &&
              (changes.groupId != source.groupId || changes.id != source.id))) {
        throw ValidationException('変更する系列が不正です');
      }
      final key = source.isAllDay
          ? DateTime.utc(original.year, original.month, original.day)
          : original.toUtc();
      final base = source.copyWith(overrides: []);
      final occurrence = _expander
          .expand(base, key, key.add(const Duration(days: 1)))
          .where((v) => v.originalStartDateTime == key)
          .firstOrNull;
      if (occurrence == null) throw ValidationException('変更する回が系列に存在しません');
      CalendarEventDto? replacement;
      CalendarEventDto? following;
      if (scope == CalendarChangeScope.only) {
        final override = CalendarEventOverride(
          originalStartDateTime: key,
          isCancelled: changes == null,
          title: changes?.title,
          startDateTime: changes?.startDateTime,
          endDateTime: changes?.endDateTime,
          isAllDay: changes?.isAllDay,
          labelId: changes?.labelId,
        );
        replacement = source.copyWith(
          overrides: [
            ...source.overrides.where(
              (v) => _key(v.originalStartDateTime, source.isAllDay) != key,
            ),
            override,
          ],
        );
      } else if (scope == CalendarChangeScope.all ||
          key == _key(source.startDateTime, source.isAllDay)) {
        if (changes != null) {
          final oldWall = source.isAllDay
              ? _key(source.startDateTime, true)
              : _expander.timeZone.local(
                  source.startDateTime,
                  source.timeZone!,
                );
          final selectedWall = source.isAllDay
              ? key
              : _expander.timeZone.local(key, source.timeZone!);
          final changedWall =
              (changes.isAllDay ||
                  (changes.timeZone ?? source.timeZone) == null)
              ? DateTime.utc(
                  changes.startDateTime.year,
                  changes.startDateTime.month,
                  changes.startDateTime.day,
                  changes.startDateTime.hour,
                  changes.startDateTime.minute,
                  changes.startDateTime.second,
                )
              : _expander.timeZone.local(
                  changes.startDateTime,
                  changes.timeZone ?? source.timeZone!,
                );
          final wall = oldWall.add(changedWall.difference(selectedWall));
          final zone = changes.timeZone ?? source.timeZone;
          final start = changes.isAllDay
              ? wall
              : zone != null
              ? _expander.timeZone.resolve(wall, zone)
              : changes.startDateTime.isUtc
              ? wall
              : DateTime(
                  wall.year,
                  wall.month,
                  wall.day,
                  wall.hour,
                  wall.minute,
                  wall.second,
                );
          if (start == null) throw ValidationException('変更後の初回の時刻が存在しません');
          replacement = _with(
            changes,
            id: source.id,
            start: start,
            rule: changes.recurrenceRule == source.recurrenceRule
                ? _moveRule(changes.recurrenceRule, oldWall, wall)
                : changes.recurrenceRule,
            end: start.add(
              changes.endDateTime.difference(changes.startDateTime),
            ),
          );
        }
      } else {
        final boundary = source.isAllDay
            ? key.subtract(const Duration(days: 1))
            : key.subtract(const Duration(seconds: 1));
        final stamp = source.isAllDay
            ? _dateText(boundary)
            : '${_dateText(boundary)}T${_timeText(boundary)}Z';
        final rule = source.recurrenceRule!
            .split(';')
            .where((v) => !v.startsWith('COUNT=') && !v.startsWith('UNTIL='))
            .join(';');
        replacement = _with(
          source,
          rule: '$rule;UNTIL=$stamp',
          overrides: source.overrides
              .where(
                (v) => _key(
                  v.originalStartDateTime,
                  source.isAllDay,
                ).isBefore(key),
              )
              .toList(),
        );
        if (changes != null) {
          var nextRule = changes.recurrenceRule;
          final parsed = CalendarRecurrenceRule.parse(source.recurrenceRule!);
          if (nextRule == source.recurrenceRule && parsed.count != null) {
            final wall = source.isAllDay
                ? _key(source.startDateTime, true)
                : _expander.timeZone.local(
                    source.startDateTime,
                    source.timeZone!,
                  );
            final before = source.isAllDay
                ? key
                : _expander.timeZone.local(key, source.timeZone!);
            final day = DateTime.utc(before.year, before.month, before.day);
            var consumed = parsed.candidateCountBefore(wall, day);
            if (!source.isAllDay) {
              consumed -= _expander.timeZone
                  .skippedDates(wall, day, source.timeZone!)
                  .where((d) => parsed.matches(d, wall))
                  .length;
            }
            nextRule = nextRule!.replaceFirst(
              RegExp(r'COUNT=\d+'),
              'COUNT=${parsed.count! - consumed}',
            );
          }
          if (changes.recurrenceRule == source.recurrenceRule) {
            nextRule = _moveRule(
              nextRule,
              _wall(source, key),
              _wall(changes, changes.startDateTime),
            );
          }
          following = _with(changes, id: '', rule: nextRule);
        }
      }
      await _repository.replaceCalendarEvent(
        CalendarEventMapper.toEntity(source),
        replacement == null ? null : CalendarEventMapper.toEntity(replacement),
        following == null ? null : CalendarEventMapper.toEntity(following),
      );
    } on ValidationException catch (e, stack) {
      Error.throwWithStackTrace(
        ApplicationValidationException(e.message),
        stack,
      );
    }
  }

  DateTime _wall(CalendarEventDto event, DateTime value) => event.isAllDay
      ? _key(value, true)
      : _expander.timeZone.local(value, event.timeZone!);

  static String? _moveRule(String? text, DateTime before, DateTime after) {
    if (text == null) return null;
    final rule = CalendarRecurrenceRule.parse(text);
    if (rule.frequency == 'WEEKLY' && rule.weekdays.isNotEmpty) {
      final shift = after.weekday - before.weekday;
      final days =
          rule.weekdays.map((day) => (day - 1 + shift) % 7 + 1).toList()
            ..sort();
      const codes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
      return text.replaceFirst(
        RegExp(r'BYDAY=[^;]+'),
        'BYDAY=${days.map((day) => codes[day - 1]).join(',')}',
      );
    }
    if (rule.frequency == 'MONTHLY' && rule.monthDay != null) {
      return text.replaceFirst(
        RegExp(r'BYMONTHDAY=\d+'),
        'BYMONTHDAY=${after.day}',
      );
    }
    if (rule.frequency == 'MONTHLY' && rule.ordinal != null) {
      final last =
          DateTime.utc(after.year, after.month, after.day + 7).month !=
          after.month;
      final ordinal = rule.ordinal == -1 && last
          ? -1
          : (after.day - 1) ~/ 7 + 1;
      const codes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
      return text.replaceFirst(
        RegExp(r'BYDAY=[^;]+'),
        'BYDAY=$ordinal${codes[after.weekday - 1]}',
      );
    }
    return text;
  }

  static DateTime _key(DateTime value, bool allDay) =>
      allDay ? DateTime.utc(value.year, value.month, value.day) : value.toUtc();
  static String _dateText(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}${value.month.toString().padLeft(2, '0')}${value.day.toString().padLeft(2, '0')}';
  static String _timeText(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}${value.minute.toString().padLeft(2, '0')}${value.second.toString().padLeft(2, '0')}';
  static CalendarEventDto _with(
    CalendarEventDto value, {
    String? id,
    DateTime? start,
    DateTime? end,
    String? rule,
    List<CalendarEventOverride> overrides = const [],
  }) => CalendarEventDto(
    id: id ?? value.id,
    groupId: value.groupId,
    labelId: value.labelId,
    title: value.title,
    startDateTime: start ?? value.startDateTime,
    endDateTime: end ?? value.endDateTime,
    isAllDay: value.isAllDay,
    recurrenceRule: rule ?? value.recurrenceRule,
    timeZone: (rule ?? value.recurrenceRule) == null || value.isAllDay
        ? null
        : value.timeZone,
    overrides: overrides,
  );
}
