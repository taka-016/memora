import 'package:uuid/uuid.dart';
import 'package:memora/domain/entities/group/group_event.dart';
import 'package:memora/domain/repositories/group/group_event_repository.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/group/sqlite_group_event_mapper.dart';

class SqliteGroupEventRepository implements GroupEventRepository {
  SqliteGroupEventRepository(this.db);
  final OfflineDatabase db;
  @override
  Future<String> saveGroupEvent(GroupEvent groupEvent) async {
    if (groupEvent.id.isEmpty) {
      final id = const Uuid().v4();
      await db.insertRow('group_events', SqliteGroupEventMapper.toRow(groupEvent.copyWith(id: id)));
      return id;
    }
    await db.updateRow('group_events', groupEvent.id, SqliteGroupEventMapper.toRow(groupEvent));
    return groupEvent.id;
  }
  @override
  Future<void> deleteGroupEvent(String groupEventId) async => db.deleteRows('group_events', 'id', groupEventId);
  @override
  Future<void> deleteGroupEventsByGroupId(String groupId) async => db.deleteRows('group_events', 'group_id', groupId);
}
