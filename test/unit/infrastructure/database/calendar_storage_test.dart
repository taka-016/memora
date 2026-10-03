import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/database/offline_database.dart';

void main() {
  late OfflineDatabase db;
  setUp(() async {
    db = OfflineDatabase(NativeDatabase.memory());
    await db.insertRow('members', {'id': 'self', 'display_name': '本人'});
    for (final id in ['family', 'friends']) {
      await db.insertRow('groups', {'id': id, 'owner_id': 'self', 'name': id});
    }
  });
  tearDown(() => db.close());

  Future<void> label(String id, String group) => db.insertRow(
    'calendar_labels',
    {'id': id, 'group_id': group, 'name': '家族全員', 'color': '#123ABC'},
  );
  Map<String, Object?> event({
    String labelId = 'label',
    String title = '旅行',
    int end = 2,
  }) => {
    'id': 'event',
    'group_id': 'family',
    'label_id': labelId,
    'title': title,
    'start_date_time': 1,
    'end_date_time': end,
    'is_all_day': 1,
  };

  test('同じグループのラベルだけを参照でき使用中のラベル削除を拒否する', () async {
    await label('label', 'family');
    await label('other', 'friends');
    await expectLater(
      db.insertRow('calendar_events', event(labelId: 'other')),
      throwsA(isA<Exception>()),
    );
    await db.insertRow('calendar_events', event());
    await expectLater(
      db.deleteRows('calendar_labels', 'id', 'label'),
      throwsA(isA<Exception>()),
    );
    await db.updateRow('calendar_labels', 'label', {
      'name': '全員',
      'color': '#FFFFFF',
    });
    expect((await db.rows('calendar_events')).single['label_id'], 'label');
    await db.deleteRows('groups', 'id', 'family');
    expect(await db.rows('calendar_events'), isEmpty);
    expect((await db.rows('calendar_labels')).single['id'], 'other');
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });

  test('復元でも空タイトル・逆転期間・不正な色と終日区分を拒否する', () async {
    await expectLater(label('missing', 'missing'), throwsA(isA<Exception>()));
    await label('label', 'family');
    for (final row in [
      event(title: '  '),
      event(end: 0),
      {...event(), 'is_all_day': 2},
    ]) {
      await expectLater(
        db.insertRow('calendar_events', row),
        throwsA(isA<Exception>()),
      );
    }
    await expectLater(
      db.updateRow('calendar_labels', 'label', {'color': '#GGGGGG'}),
      throwsA(isA<Exception>()),
    );
  });

  test('バージョン1のDBを既存データを保ったまま移行する', () async {
    final directory = await Directory.systemTemp.createTemp('memora-calendar-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/old.sqlite');
    var old = OfflineDatabase(NativeDatabase(file));
    await old.insertRow('members', {'id': 'self', 'display_name': '本人'});
    await old.customStatement('DROP TABLE IF EXISTS calendar_events');
    await old.customStatement('DROP TABLE IF EXISTS calendar_labels');
    await old.customStatement('PRAGMA user_version = 1');
    await old.close();
    old = OfflineDatabase(NativeDatabase(file));
    addTearDown(old.close);
    await old.initialize();
    expect((await old.rows('members')).single['display_name'], '本人');
    expect(await old.rows('calendar_events'), isEmpty);
    expect(await old.rows('calendar_labels'), isEmpty);
    expect(old.schemaVersion, 3);
  });
  test('文字色は任意のRGB色を保存し不正な色を拒否する', () async {
    await label('label', 'family');
    await db.updateRow('calendar_labels', 'label', {'text_color': '#Ab12Cd'});
    expect((await db.rows('calendar_labels')).single['text_color'], '#Ab12Cd');
    await expectLater(
      db.updateRow('calendar_labels', 'label', {'text_color': '#GGGGGG'}),
      throwsA(isA<Exception>()),
    );
  });

  test('バージョン2のラベルと予定を保ち既存の文字色を補完する', () async {
    final directory = await Directory.systemTemp.createTemp(
      'memora-calendar-color-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/old.sqlite');
    var old = OfflineDatabase(NativeDatabase(file));
    await old.insertRow('members', {'id': 'self', 'display_name': '本人'});
    await old.insertRow('groups', {
      'id': 'family',
      'owner_id': 'self',
      'name': '家族',
    });
    await old.customStatement('DROP TABLE calendar_events');
    await old.customStatement('DROP TABLE calendar_labels');
    await old.customStatement(
      "CREATE TABLE calendar_labels (id TEXT PRIMARY KEY, group_id TEXT NOT NULL REFERENCES groups(id), name TEXT NOT NULL, color TEXT NOT NULL, UNIQUE (id, group_id))",
    );
    await old.insertRow('calendar_labels', {
      'id': 'light',
      'group_id': 'family',
      'name': '明色',
      'color': '#FFFFFF',
    });
    await old.insertRow('calendar_labels', {
      'id': 'dark',
      'group_id': 'family',
      'name': '暗色',
      'color': '#123ABC',
    });
    await old.customStatement(
      'CREATE TABLE calendar_events (id TEXT PRIMARY KEY, group_id TEXT NOT NULL REFERENCES groups(id), label_id TEXT NOT NULL, title TEXT NOT NULL, start_date_time INTEGER NOT NULL, end_date_time INTEGER NOT NULL, is_all_day INTEGER NOT NULL, FOREIGN KEY (label_id, group_id) REFERENCES calendar_labels(id, group_id))',
    );
    await old.insertRow('calendar_events', {...event(labelId: 'dark')});
    await old.customStatement('PRAGMA user_version = 2');
    await old.close();
    old = OfflineDatabase(NativeDatabase(file));
    addTearDown(old.close);
    final rows = await old.rows('calendar_labels');
    expect((await old.rows('calendar_events')).single['label_id'], 'dark');
    expect(
      rows.firstWhere((row) => row['id'] == 'light')['text_color'],
      '#000000',
    );
    expect(
      rows.firstWhere((row) => row['id'] == 'dark')['text_color'],
      '#FFFFFF',
    );
    expect(await old.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });
}
