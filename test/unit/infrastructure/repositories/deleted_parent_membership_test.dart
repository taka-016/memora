import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/mappers/group/group_mapper.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/infrastructure/queries/group/firestore_group_query_service.dart';
import 'package:memora/infrastructure/repositories/group/firestore_group_repository.dart';
import 'package:memora/infrastructure/repositories/member/firestore_member_repository.dart';

import '../../../helpers/test_exception.dart';
import 'calendar/firestore_calendar_repository_test.mocks.dart';

void main() {
  test('メンバー退避後の再取得と所属差分の繰り返し保存で退避済み所属を保持する', () async {
    final store = _Store();
    store.rows['groups/g'] = {'ownerId': 'a', 'name': '家族'};
    for (final id in ['a', 'b', 'c', 'd']) {
      store.rows['members/$id'] = {'displayName': id, 'version': 3};
    }
    for (final id in ['a', 'b', 'c']) {
      store.rows['group_members/$id'] = {
        'groupId': 'g',
        'memberId': id,
        'isAdministrator': id == 'b',
        'orderIndex': id.codeUnitAt(0),
      };
    }
    await FirestoreMemberRepository(firestore: store.firestore)
        .deleteMember('b', expectedVersion: 3);
    expect(store.rows['deleted_members/b'], {'displayName': 'b', 'version': 3});
    final hidden = Map.of(store.rows['group_members/b']!);
    final query = FirestoreGroupQueryService(firestore: store.firestore);
    final repo = FirestoreGroupRepository(firestore: store.firestore);
    var group = (await query.getManagedGroupsWithMembersByOwnerId('a')).single;
    expect(group.members.map((m) => m.memberId), ['a', 'c']);
    store.written.clear();
    await repo.updateGroup(GroupMapper.toEntity(group.copyWith(name: '変更')));
    expect(store.written, ['groups/g']);
    group = (await query.getGroupWithMembersById('g'))!;
    final edited = group.copyWith(
      members: [
        group.members.first.copyWith(isAdministrator: true, orderIndex: 0),
        const GroupMemberDto(
          groupId: 'g',
          memberId: 'd',
          displayName: 'd',
          orderIndex: 1,
        ),
      ],
    );
    await repo.updateGroup(GroupMapper.toEntity(edited));
    await repo.updateGroup(GroupMapper.toEntity(edited));
    expect(store.rows['group_members/b'], hidden);
    final result = (await query.getGroupWithMembersById('g'))!;
    expect(result.members.map((m) => m.memberId), ['a', 'd']);
    expect(result.members.first.isAdministrator, isTrue);
    expect(
      store.rows.keys.where((k) => k.startsWith('group_members/')),
      hasLength(3),
    );
    final before = {for (final e in store.rows.entries) e.key: Map.of(e.value)};
    store.commitError = TestException('所属保存失敗');
    await expectLater(
      repo.updateGroup(
        GroupMapper.toEntity(result.copyWith(name: '失敗', members: [])),
      ),
      throwsA(isA<TestException>()),
    );
    expect(store.rows, before);
  });
  for (final table in ['groups', 'members']) {
    test('$tableの退避は全関連データを維持し書き込み失敗時は元データを維持する', () async {
      final store = _Store();
      final source = '$table/id';
      store.rows[source] = {
        'name': '削除時の情報',
        'ownerId': 'owner',
        'updatedAt': Timestamp(1, 0),
        'version': 3,
      };
      for (final collection in [
        'group_members',
        'trip_entries',
        'locations',
        'tasks',
        'itinerary_items',
        'group_events',
        'member_events',
        'calendar_events',
        'calendar_event_overrides',
        'calendar_labels',
        'dvc_point_contracts',
        'dvc_limited_points',
        'dvc_point_usages',
      ]) {
        store.rows['$collection/child'] = {
          'groupId': 'id',
          'memberId': 'id',
          'assignedMemberId': 'id',
        };
      }
      final before = {
        for (final e in store.rows.entries) e.key: Map.of(e.value),
      };
      Future<void> remove() => table == 'groups'
          ? FirestoreGroupRepository(firestore: store.firestore)
                .deleteGroup('id')
          : FirestoreMemberRepository(firestore: store.firestore)
                .deleteMember('id', expectedVersion: 3);
      store.commitError = TestException('退避書き込み失敗');
      await expectLater(remove(), throwsA(isA<TestException>()));
      expect(store.rows, before);
      store.commitError = null;
      await remove();
      expect(store.rows[source], isNull);
      expect(store.rows['deleted_$table/id'], before[source]);
      for (final e in before.entries.where((e) => e.key != source)) {
        expect(store.rows[e.key], e.value, reason: e.key);
      }
      expect(
        await FirestoreGroupQueryService(firestore: store.firestore)
            .getGroupWithMembersById('id'),
        isNull,
      );
    });
  }
}

class _Store {
  final firestore = MockFirebaseFirestore();
  final rows = <String, Map<String, dynamic>>{};
  final written = <String>[];
  Object? commitError;
  int nextId = 0;
  _Store() {
    final collections = <String, MockCollectionReference>{};
    MockDocumentReference reference(String path) {
      final ref = MockDocumentReference();
      when(ref.id).thenReturn(path.split('/').last);
      when(ref.path).thenReturn(path);
      when(ref.get()).thenAnswer((_) async => document(path));
      return ref;
    }

    when(firestore.collection(any)).thenAnswer((call) {
      final name = call.positionalArguments.single as String;
      return collections.putIfAbsent(name, () {
        final collection = MockCollectionReference();
        when(collection.doc(any)).thenAnswer(
          (call) => reference(
            '$name/${call.positionalArguments.single ?? 'new${nextId++}'}',
          ),
        );
        when(collection.where(any, isEqualTo: anyNamed('isEqualTo')))
            .thenAnswer((call) {
              final query = MockQuery();
              when(query.get()).thenAnswer((_) async {
                final snapshot = MockQuerySnapshot();
                final documents = [
                  for (final e in rows.entries)
                    if (e.key.startsWith('$name/') &&
                        e.value[call.positionalArguments.single] ==
                            call.namedArguments[#isEqualTo])
                      document(e.key),
                ];
                when(snapshot.docs).thenReturn(documents);
                return snapshot;
              });
              return query;
            });
        return collection;
      });
    });
    void configure(dynamic writer, List<void Function()> pending) {
      when(writer.set(any, any)).thenAnswer((call) {
        final path = (call.positionalArguments[0] as DocumentReference).path;
        final data = Map<String, dynamic>.from(
          call.positionalArguments[1] as Map,
        );
        pending.add(() {
          rows[path] = data;
          written.add(path);
        });
        return writer;
      });
      when(writer.update(any, any)).thenAnswer((call) {
        final path = (call.positionalArguments[0] as DocumentReference).path;
        final data = Map<String, dynamic>.from(
          call.positionalArguments[1] as Map,
        );
        pending.add(() {
          rows[path]!.addAll(data);
          written.add(path);
        });
        return writer;
      });
      when(writer.delete(any)).thenAnswer((call) {
        final path = (call.positionalArguments[0] as DocumentReference).path;
        pending.add(() {
          rows.remove(path);
          written.add(path);
        });
        return writer;
      });
    }

    when(firestore.batch()).thenAnswer((_) {
      final batch = MockWriteBatch();
      final pending = <void Function()>[];
      configure(batch, pending);
      when(batch.commit()).thenAnswer((_) async {
        if (commitError case final error?) throw error;
        for (final action in pending) {
          action();
        }
      });
      return batch;
    });
    when(firestore.runTransaction<void>(any)).thenAnswer((call) async {
      final tx = MockTransaction();
      final pending = <void Function()>[];
      configure(tx, pending);
      when(tx.get(any)).thenAnswer(
        (call) async => document(
          (call.positionalArguments.single as DocumentReference).path,
        ),
      );
      await (call.positionalArguments.single as TransactionHandler<void>)(tx);
      if (commitError case final error?) throw error;
      for (final action in pending) {
        action();
      }
    });
  }
  MockQueryDocumentSnapshot document(String path) {
    final doc = MockQueryDocumentSnapshot();
    when(doc.id).thenReturn(path.split('/').last);
    when(doc.exists).thenReturn(rows.containsKey(path));
    when(doc.data()).thenAnswer((_) => rows[path] ?? {});
    final ref = MockDocumentReference();
    when(ref.path).thenReturn(path);
    when(ref.id).thenReturn(path.split('/').last);
    when(doc.reference).thenReturn(ref);
    return doc;
  }
}
