import 'package:memora/domain/entities/calendar/calendar_event.dart';

import '../../../scripts/timetree/import_timetree.dart' as timetree;

import 'package:flutter_test/flutter_test.dart';

import '../../../scripts/firebase/migrate_firestore_read_models.dart'
    as migration;

void main() {
  test('移行適用は出力先の後に明示した--applyだけで有効になり引数不足を拒否する', () {
    expect(
      () => migration.migrationArguments(['p', '--apply']),
      throwsFormatException,
    );
    expect(
      () => migration.migrationArguments(['p', 'report.json', 'unexpected']),
      throwsFormatException,
    );
    expect(migration.migrationArguments(['p', 'report.json']).apply, isFalse);
    expect(
      migration.migrationArguments(['p', 'report.json', '--apply']).apply,
      isTrue,
    );
  });
  test('既存旅程のグループIDは親の旅行から補完し他の項目を変更しない', () {
    final parent = <String, dynamic>{
      'name': 'root/trip_entries/trip',
      'updateTime': 'parent-time',
      'fields': {
        'groupId': {'stringValue': 'g'},
        'version': {'integerValue': '7'},
      },
    };
    final item = <String, dynamic>{
      'name': 'root/itinerary_items/item',
      'updateTime': 'item-time',
      'fields': {
        'tripId': {'stringValue': 'trip'},
        'name': {'stringValue': '旅程'},
        'memo': {'stringValue': '詳細'},
      },
    };
    final writes = migration.itineraryGroupMigrationWrites(parent, [item]);
    expect(writes, hasLength(2));
    final child = writes.singleWhere(
      (write) =>
          (write['update'] as Map)['name'] == 'root/itinerary_items/item',
    );
    expect(child['currentDocument'], {'updateTime': 'item-time'});
    expect(child['updateMask'], {
      'fieldPaths': ['groupId'],
    });
    expect((child['update'] as Map)['fields'], {
      'groupId': {'stringValue': 'g'},
    });
    final head = writes.singleWhere(
      (write) => (write['update'] as Map)['name'] == 'root/trip_entries/trip',
    );
    expect(head['currentDocument'], {'updateTime': 'parent-time'});
    expect((head['update'] as Map)['fields'], {
      'version': {'integerValue': '8'},
    });
    final migrated = {
      ...item,
      'fields': {
        ...(item['fields'] as Map),
        'groupId': {'stringValue': 'g'},
      },
    };
    expect(
      migration.itineraryGroupMigrationWrites(parent, [migrated]),
      isEmpty,
    );
  });
  final parent = <String, Object?>{
    'groupId': 'g',
    'title': '系列',
    'labelType': 'group',
    'labelId': null,
    'memberId': null,
    'startDateTime': DateTime.utc(2026, 1, 1),
    'endDateTime': DateTime.utc(2026, 1, 3),
    'isAllDay': true,
    'recurrenceRule': 'FREQ=DAILY;COUNT=5',
    'timeZone': null,
    'version': 7,
    'referencedLabelIds': ['label'],
    'overrideIds': ['changed', 'cancelled'],
  };
  final changed = <String, Object?>{
    'eventId': 'series',
    'groupId': 'g',
    'originalStartDateTime': DateTime.utc(2026, 1, 2),
    'isCancelled': false,
    'title': '移動した予定',
    'labelType': 'custom',
    'labelId': 'label',
    'memberId': null,
    'startDateTime': DateTime.utc(2026, 2, 1),
    'endDateTime': DateTime.utc(2026, 2, 2),
    'isAllDay': true,
    'url': 'https://example.com',
    'memo': '一行目\n二行目',
    'locationName': '駅',
    'latitude': 35.0,
    'longitude': 139.0,
    'notificationMinutesBefore': [0, 1440],
  };
  test('今後の一括取り込みも検索境界と新しい保存形式を設定する', () {
    final record = timetree.TimeTreeImportEvent(
      CalendarEvent(
        id: '',
        groupId: 'g',
        labelType: 'group',
        title: '予定',
        startDateTime: DateTime.utc(2026, 1, 1),
        endDateTime: DateTime.utc(2026, 1, 3),
        isAllDay: true,
        recurrenceRule: 'FREQ=DAILY;COUNT=2',
      ),
      DateTime.utc(2026),
      DateTime.utc(2026),
      'uid',
      '',
    );
    expect(record.document()['calendarFormatVersion'], 2);
    expect(
      record.document()['recurrenceEndDateTime'],
      DateTime.utc(2026, 1, 4),
    );
  });
  test('既存の個別変更を紐付けのない通常予定へ移し元の回の取消を保持する', () {
    final plan = migration.buildCalendarMigrationPlan('series', parent, {
      'changed': changed,
      'cancelled': {
        'originalStartDateTime': DateTime.utc(2026, 1, 3),
        'isCancelled': true,
      },
    }, newId: () => 'new-id')!;
    final normal = plan.independent['new-id']!;
    for (final field in [
      'title',
      'labelType',
      'labelId',
      'startDateTime',
      'endDateTime',
      'isAllDay',
      'url',
      'memo',
      'locationName',
      'latitude',
      'longitude',
      'notificationMinutesBefore',
    ]) {
      expect(normal[field], changed[field]);
    }
    expect(normal.containsKey('eventId'), isFalse);
    expect(normal.containsKey('originalStartDateTime'), isFalse);
    expect(normal['recurrenceRule'], isNull);
    expect(plan.cancellations['changed']!['isCancelled'], isTrue);
    expect(
      plan.cancellations['changed']!['originalEndDateTime'],
      DateTime.utc(2026, 1, 4),
    );
    expect(
      plan.cancellations['cancelled']!['originalEndDateTime'],
      DateTime.utc(2026, 1, 5),
    );
    expect(plan.parent['recurrenceEndDateTime'], DateTime.utc(2026, 1, 7));
    expect(plan.parent['version'], 8);
    expect(plan.parent['referencedLabelIds'], isEmpty);
    expect(plan.labelDeltas, isEmpty);
    expect(
      migration.buildCalendarMigrationPlan(
        'series',
        plan.parent,
        plan.cancellations,
      ),
      isNull,
    );
  });
  test('系列・取消・独立予定とラベル参照数を期待時点付きの1つの一括保存へ含める', () {
    const root = 'projects/p/databases/(default)/documents';
    var number = 0;
    final plan = migration.buildCalendarMigrationPlan('series', parent, {
      'a': changed,
      'b': {...changed, 'originalStartDateTime': DateTime.utc(2026, 1, 4)},
    }, newId: () => 'new-${number++}')!;
    final writes = migration.calendarMigrationWrites(
      plan,
      {'name': '$root/calendar_events/series', 'updateTime': 'parent-time'},
      {
        for (final id in ['a', 'b'])
          id: {
            'name': '$root/calendar_event_overrides/$id',
            'updateTime': 'child-time',
          },
      },
      {
        'label': {
          'name': '$root/calendar_labels/label',
          'updateTime': 'label-time',
          'fields': {
            'eventCount': {'integerValue': '2'},
            'version': {'integerValue': '9'},
          },
        },
      },
      root,
    );
    expect(writes, hasLength(6));
    final label = writes.singleWhere(
      (value) =>
          (value['update'] as Map)['name'] == '$root/calendar_labels/label',
    );
    expect(label['currentDocument'], {'updateTime': 'label-time'});
    final labelFields = ((label['update'] as Map)['fields'] as Map);
    expect(labelFields['eventCount'], {'integerValue': '3'});
    expect(labelFields['version'], {'integerValue': '9'});
    expect(
      writes.where(
        (value) => (value['currentDocument'] as Map)['exists'] == false,
      ),
      hasLength(2),
    );
    expect(
      writes.where(
        (value) =>
            (value['currentDocument'] as Map)['updateTime'] == 'child-time',
      ),
      hasLength(2),
    );
    final updatedParent = writes.singleWhere(
      (value) =>
          (value['update'] as Map)['name'] == '$root/calendar_events/series',
    );
    expect(updatedParent['currentDocument'], {'updateTime': 'parent-time'});
  });
  test('複数の個別変更を通常予定へ分けたラベル参照件数の差分を算出する', () {
    var number = 0;
    final plan = migration.buildCalendarMigrationPlan('series', parent, {
      'a': changed,
      'b': {...changed, 'originalStartDateTime': DateTime.utc(2026, 1, 4)},
    }, newId: () => 'normal-${number++}')!;
    expect(plan.independent, hasLength(2));
    expect(plan.labelDeltas, {'label': 1});
  });
}
