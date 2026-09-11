import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/exceptions/feature_unavailable_exception.dart';
import 'package:memora/domain/entities/trip/itinerary_item.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/domain/entities/trip/location.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/trip/sqlite_itinerary_item_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/sqlite_trip_entry_mapper.dart';

void main() {
  test('復元用のMapperも場所情報を捨てず共通の利用不可結果で拒否する', () {
    expect(
      () => SqliteItineraryItemMapper.toRow(
        ItineraryItem(
          id: 'item',
          tripId: 'trip',
          name: '観光',
          locationId: 'location',
        ),
      ),
      throwsA(isA<FeatureUnavailableException>()),
    );
    expect(
      () => SqliteTripEntryMapper.toRow(
        TripEntry(
          id: 'trip',
          groupId: 'group',
          year: 2026,
          locations: [
            Location(
              id: 'location',
              tripId: 'trip',
              groupId: 'group',
              latitude: 35,
              longitude: 139,
            ),
          ],
        ),
      ),
      throwsA(isA<FeatureUnavailableException>()),
    );
    expect(
      () => SqliteTripEntryMapper.toRow(
        TripEntry(
          id: 'trip',
          groupId: 'group',
          year: 2026,
          itineraryItems: [
            ItineraryItem(
              id: 'item',
              tripId: 'trip',
              name: '観光',
              locationId: 'location',
            ),
          ],
        ),
      ),
      throwsA(isA<FeatureUnavailableException>()),
    );
  });

  test('スキーマが禁止データを含まず必須値と一意性と外部キーを検証する', () async {
    final db = OfflineDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.initialize();
    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    expect(
      tables.map((r) => r.read<String>('name')),
      isNot(contains('locations')),
    );
    expect(
      tables.map((r) => r.read<String>('name')),
      isNot(contains('member_invitations')),
    );
    final columns = await db.customSelect('PRAGMA table_info(members)').get();
    expect(
      columns.map((r) => r.read<String>('name')),
      isNot(contains('passport_number')),
    );
    expect(
      columns.map((r) => r.read<String>('name')),
      isNot(contains('passport_expiration')),
    );
    await expectLater(
      db.customStatement("INSERT INTO members (id) VALUES ('invalid')"),
      throwsA(isA<Exception>()),
    );
    await db.customStatement(
      "INSERT INTO members (id, display_name, account_id) VALUES ('self', '本人', 'account')",
    );
    await expectLater(
      db.customStatement(
        "INSERT INTO members (id, display_name, account_id) VALUES ('other', '別人', 'account')",
      ),
      throwsA(isA<Exception>()),
    );
    await db.customStatement(
      'INSERT INTO "groups" (id, owner_id, name) VALUES (?, ?, ?)',
      ['group', 'self', '家族'],
    );
    await expectLater(
      db.customStatement(
        'INSERT INTO group_members (group_id, member_id, is_administrator, order_index) VALUES (?, ?, ?, ?)',
        ['group', 'missing', 0, 0],
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      db.customStatement(
        'INSERT INTO group_members (group_id, member_id, is_administrator, order_index) VALUES (?, ?, ?, ?)',
        ['group', 'self', 2, 0],
      ),
      throwsA(isA<Exception>()),
    );
    await db.customStatement(
      'INSERT INTO group_members (group_id, member_id, is_administrator, order_index) VALUES (?, ?, ?, ?)',
      ['group', 'self', 1, 0],
    );
    await expectLater(
      db.customStatement(
        'INSERT INTO group_members (group_id, member_id, is_administrator, order_index) VALUES (?, ?, ?, ?)',
        ['group', 'self', 0, 1],
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      db.deleteRows('members', 'id', 'self'),
      throwsA(isA<Exception>()),
    );
    await db.deleteRows('groups', 'id', 'group');
    expect(await db.rows('group_members'), isEmpty);
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });

  test('未対応バージョンのDBを初期化し直さず拒否する', () async {
    final directory = await Directory.systemTemp.createTemp('memora-schema-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/test.sqlite');
    var db = OfflineDatabase(NativeDatabase(file));
    await db.initialize();
    await db.customStatement(
      "INSERT INTO members (id, display_name) VALUES ('self', '本人')",
    );
    await db.customStatement('PRAGMA user_version = 2');
    await db.close();
    db = OfflineDatabase(NativeDatabase(file));
    await expectLater(db.initialize(), throwsStateError);
    await db.close();
  });
}
