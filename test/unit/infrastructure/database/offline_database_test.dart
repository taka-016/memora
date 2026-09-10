import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/exceptions/feature_unavailable_exception.dart';
import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/domain/entities/group/group.dart';
import 'package:memora/domain/entities/group/group_member.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/domain/entities/trip/itinerary_item.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/repositories/member/sqlite_member_repository.dart';
import 'package:memora/infrastructure/repositories/group/sqlite_group_repository.dart';
import 'package:memora/infrastructure/repositories/trip/sqlite_trip_entry_repository.dart';
import 'package:memora/infrastructure/queries/group/sqlite_group_query_service.dart';
import 'package:memora/infrastructure/queries/trip/sqlite_trip_entry_query_service.dart';
import 'package:memora/infrastructure/transactions/sqlite_write_transaction.dart';

void main() {
  late OfflineDatabase db;
  late String groupId;
  setUp(() async {
    db = OfflineDatabase(NativeDatabase.memory());
    await SqliteMemberRepository(db).saveMember(const Member(id: '', displayName: '本人'));
    final rows = await db.customSelect('SELECT id FROM members').get();
    final memberId = rows.single.read<String>('id');
    groupId = await SqliteGroupRepository(db).saveGroup(Group(id: '', ownerId: memberId, name: '家族', members: [GroupMember(groupId: '', memberId: memberId, orderIndex: 2, isAdministrator: true)]));
  });
  tearDown(() async => db.close());

  test('グループの所属とメンバー情報を組み立てて取得する', () async {
    final group = await SqliteGroupQueryService(db).getGroupWithMembersById(groupId);
    expect(group!.members.single.displayName, '本人');
    expect(group.members.single.isAdministrator, isTrue);
    expect(group.members.single.orderIndex, 2);
    await SqliteGroupRepository(db).updateGroup(Group(id: groupId, ownerId: group.ownerId, name: '変更', members: []));
    expect((await SqliteGroupQueryService(db).getGroupWithMembersById(groupId))!.members, isEmpty);
  });

  test('旅行を場所なしで保存し日時とタスクの並び順を復元して更新削除する', () async {
    final repository = SqliteTripEntryRepository(db);
    final query = SqliteTripEntryQueryService(db);
    final date = DateTime(2026, 9, 10, 12, 34, 56, 123, 456);
    final id = await repository.saveTripEntry(TripEntry(id: '', groupId: groupId, year: 2026, tasks: [
      Task(id: 'child', tripId: '', orderIndex: 1, name: '子', isCompleted: false, parentTaskId: 'parent', dueDate: date),
      Task(id: 'parent', tripId: '', orderIndex: 0, name: '親', isCompleted: false),
    ], itineraryItems: [ItineraryItem(id: 'item', tripId: '', name: '朝食', startDateTime: date)]));
    final trip = (await query.getTripEntryById(id, tasksOrderBy: [const OrderBy('orderIndex')]))!;
    expect(trip.locations, isEmpty);
    expect(trip.tasks.map((task) => task.id), ['parent', 'child']);
    expect(trip.tasks.last.dueDate, date);
    expect(trip.itineraryItems.single.locationId, isNull);
    expect(trip.itineraryItems.single.location, isNull);
    expect(trip.itineraryItems.single.startDateTime, date);
    await repository.updateTripEntry(TripEntry(id: id, groupId: groupId, year: 2027));
    expect((await query.getTripEntryById(id))!.tasks, isEmpty);
    expect(await query.getTripEntriesByGroupIdAndYear(groupId, 2026), isEmpty);
    await repository.deleteTripEntry(id);
    expect(await query.getTripEntryById(id), isNull);
  });

  test('場所付き入力を拒否して既存の旅行を維持する', () async {
    final repository = SqliteTripEntryRepository(db);
    final id = await repository.saveTripEntry(TripEntry(id: '', groupId: groupId, year: 2026));
    await expectLater(repository.updateTripEntry(TripEntry(id: id, groupId: groupId, year: 2027, itineraryItems: [ItineraryItem(id: 'item', tripId: id, name: '観光', locationId: 'location')])), throwsA(isA<FeatureUnavailableException>()));
    expect((await SqliteTripEntryQueryService(db).getTripEntryById(id))!.year, 2026);
  });

  test('複数の保存途中で失敗した場合は全件ロールバックする', () async {
    await expectLater(SqliteWriteTransaction(db).run((scope) async {
      final repository = scope.repository<TripEntryRepository>();
      await repository.saveTripEntry(TripEntry(id: '', groupId: groupId, year: 2026));
      await repository.saveTripEntry(TripEntry(id: '', groupId: 'missing', year: 2026));
    }), throwsA(isA<Exception>()));
    expect(await SqliteTripEntryQueryService(db).getTripEntriesByGroupId(groupId), isEmpty);
  });
}
