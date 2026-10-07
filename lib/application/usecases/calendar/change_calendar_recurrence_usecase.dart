import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/application/mappers/calendar/calendar_event_mapper.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_expander.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:memora/domain/entities/calendar/calendar_event.dart';
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
      if (scope != CalendarChangeScope.only &&
          source.overrides.any(
            (value) =>
                _key(value.originalStartDateTime, source.isAllDay) == key,
          )) {
        throw ValidationException('個別変更した予定から繰り返し全体を変更できません。個別変更をリセットしてください');
      }
      if (!source.overrides.any(
        (value) => _key(value.originalStartDateTime, source.isAllDay) == key,
      )) {
        final occurrence = _expander
            .expand(
              source.copyWith(overrides: []),
              key,
              key.add(const Duration(days: 1)),
            )
            .where((value) => value.originalStartDateTime == key)
            .firstOrNull;
        if (occurrence == null) throw ValidationException('変更する回が系列に存在しません');
      }
      CalendarEventDto? replacement;
      CalendarEventDto? following;
      final preservedEvents = <CalendarEvent>[];
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
          if (changes.recurrenceRule == null) {
            preservedEvents.addAll(_individualEvents(source, source.overrides));
          }
          final movedRule = _moveRule(
            changes.recurrenceRule,
            _sameSchedule(changes.recurrenceRule, source.recurrenceRule)
                ? oldWall
                : changedWall,
            wall,
          );
          replacement = _with(
            changes,
            id: source.id,
            start: start,
            rule: movedRule,
            end: start.add(
              changes.endDateTime.difference(changes.startDateTime),
            ),
            overrides: changes.recurrenceRule == null
                ? []
                : _moveOverrides(
                    source,
                    changes,
                    source.overrides,
                    source.startDateTime,
                    start,
                    movedRule!,
                  ),
          );
          if (changes.recurrenceRule == null &&
              source.overrides.any(
                (value) =>
                    _key(value.originalStartDateTime, source.isAllDay) ==
                    _key(source.startDateTime, source.isAllDay),
              )) {
            replacement = null;
          }
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
          if (nextRule != null &&
              parsed.count != null &&
              CalendarRecurrenceRule.parse(nextRule).count == parsed.count) {
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
          if (parsed.frequency == 'MONTHLY' &&
              parsed.ordinal == null &&
              parsed.monthDay == null &&
              nextRule != null &&
              _sameSchedule(changes.recurrenceRule, source.recurrenceRule)) {
            nextRule =
                '$nextRule;BYMONTHDAY=${_wall(source, source.startDateTime).day}';
          }
          if (_sameSchedule(changes.recurrenceRule, source.recurrenceRule)) {
            nextRule = _moveRule(
              nextRule,
              _wall(source, key),
              _wall(changes, changes.startDateTime),
            );
          }
          if (nextRule == null) {
            preservedEvents.addAll(
              _individualEvents(
                source,
                source.overrides
                    .where(
                      (value) => !_key(
                        value.originalStartDateTime,
                        source.isAllDay,
                      ).isBefore(key),
                    )
                    .toList(),
              ),
            );
          }
          following = _with(
            changes,
            id: '',
            rule: nextRule,
            overrides: nextRule == null
                ? []
                : _moveOverrides(
                    source,
                    changes,
                    source.overrides
                        .where(
                          (value) => !_key(
                            value.originalStartDateTime,
                            source.isAllDay,
                          ).isBefore(key),
                        )
                        .toList(),
                    key,
                    changes.startDateTime,
                    nextRule,
                  ),
          );
        }
      }
      final head = replacement == null
          ? null
          : CalendarEventMapper.toEntity(replacement);
      final tail = following == null
          ? null
          : CalendarEventMapper.toEntity(following);
      if (preservedEvents.isEmpty) {
        await _repository.replaceCalendarEvent(
          CalendarEventMapper.toEntity(source),
          head,
          tail,
        );
      } else {
        await _repository.replaceCalendarEvent(
          CalendarEventMapper.toEntity(source),
          head,
          tail,
          preservedEvents: preservedEvents,
        );
      }
    } on ValidationException catch (e, stack) {
      Error.throwWithStackTrace(
        ApplicationValidationException(e.message),
        stack,
      );
    }
  }

  Future<void> resetOverride(CalendarEventDto source, DateTime original) async {
    final key = _key(original, source.isAllDay);
    if (source.id.isEmpty ||
        source.recurrenceRule == null ||
        !source.overrides.any(
          (value) => _key(value.originalStartDateTime, source.isAllDay) == key,
        )) {
      throw const ApplicationValidationException(
        'リセットする個別変更が見つかりません。再読み込みしてください',
      );
    }
    final replacement = source.copyWith(
      overrides: source.overrides
          .where(
            (value) =>
                _key(value.originalStartDateTime, source.isAllDay) != key,
          )
          .toList(),
    );
    try {
      await _repository.replaceCalendarEvent(
        CalendarEventMapper.toEntity(source),
        CalendarEventMapper.toEntity(replacement),
        null,
      );
    } on ValidationException catch (e, stack) {
      Error.throwWithStackTrace(
        ApplicationValidationException(e.message),
        stack,
      );
    }
  }

  List<CalendarEvent> _individualEvents(
    CalendarEventDto source,
    List<CalendarEventOverride> overrides,
  ) => overrides
      .where((value) => !value.isCancelled)
      .map(
        (value) => CalendarEvent(
          id: '',
          groupId: source.groupId,
          labelId: value.labelId!,
          title: value.title!,
          startDateTime: value.startDateTime!,
          endDateTime: value.endDateTime!,
          isAllDay: value.isAllDay!,
        ),
      )
      .toList();

  List<CalendarEventOverride> _moveOverrides(
    CalendarEventDto source,
    CalendarEventDto target,
    List<CalendarEventOverride> overrides,
    DateTime before,
    DateTime after,
    String targetRule,
  ) {
    final beforeWall = _wall(source, before);
    final afterWall = _wall(target, after);
    final shift = afterWall.difference(beforeWall);
    final originalRule = CalendarRecurrenceRule.parse(source.recurrenceRule!);
    final nextRule = CalendarRecurrenceRule.parse(targetRule);
    final first = _wall(source, source.startDateTime);
    return overrides.map((value) {
      final original = _wall(source, value.originalStartDateTime);
      var wall = original.add(shift);
      if (originalRule.frequency == 'MONTHLY' &&
          originalRule.ordinal == null &&
          nextRule.frequency == 'MONTHLY' &&
          nextRule.ordinal == null &&
          originalRule.matches(
            DateTime.utc(original.year, original.month, original.day),
            first,
          )) {
        final offset =
            (original.year - beforeWall.year) * 12 +
            original.month -
            beforeWall.month;
        final month = DateTime.utc(afterWall.year, afterWall.month + offset);
        final lastDay = DateTime.utc(month.year, month.month + 1, 0).day;
        final requested = nextRule.monthDay ?? afterWall.day;
        wall = DateTime.utc(
          month.year,
          month.month,
          requested > lastDay ? lastDay : requested,
          wall.hour,
          wall.minute,
          wall.second,
          wall.millisecond,
          wall.microsecond,
        );
      }
      final key = target.isAllDay
          ? _key(wall, true)
          : _expander.resolveTime(wall, target.timeZone!);
      return CalendarEventOverride(
        originalStartDateTime: key,
        isCancelled: value.isCancelled,
        title: value.title,
        labelId: value.labelId,
        isAllDay: value.isAllDay,
        startDateTime: value.startDateTime,
        endDateTime: value.endDateTime,
      );
    }).toList();
  }

  DateTime _wall(CalendarEventDto event, DateTime value) => event.isAllDay
      ? _key(value, true)
      : _expander.timeZone.local(value, event.timeZone!);

  static bool _sameSchedule(String? before, String? after) {
    if (before == null || after == null) return false;
    final first = CalendarRecurrenceRule.parse(before);
    final second = CalendarRecurrenceRule.parse(after);
    return first.frequency == second.frequency &&
        first.interval == second.interval &&
        first.monthDay == second.monthDay &&
        first.ordinal == second.ordinal &&
        first.weekdays.length == second.weekdays.length &&
        first.weekdays.every(second.weekdays.contains);
  }

  static String? _moveRule(String? text, DateTime before, DateTime after) {
    if (text == null) return null;
    if (before.year == after.year &&
        before.month == after.month &&
        before.day == after.day)
      return text;
    final rule = CalendarRecurrenceRule.parse(text);
    const codes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    if (rule.frequency == 'WEEKLY' && rule.weekdays.isNotEmpty) {
      final shift = after.weekday - before.weekday;
      final days =
          rule.weekdays.map((day) => (day - 1 + shift) % 7 + 1).toList()
            ..sort();
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
