import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';

import '../unit/infrastructure/repositories/calendar/firestore_calendar_repository_test.mocks.dart';

class FirestoreTransactionStore {
  final firestore = MockFirebaseFirestore();
  final rows = <String, Map<String, dynamic>>{};
  void Function()? beforeRetry;
  Object? commitError;
  Future<void> Function()? beforeCommit;
  int commits = 0;
  final reads = <String>[];

  FirestoreTransactionStore() {
    when(firestore.collection(any)).thenAnswer((call) {
      final name = call.positionalArguments.single as String;
      final collection = MockCollectionReference();
      when(collection.doc(any)).thenAnswer(
        (call) => reference('$name/${call.positionalArguments.single}'),
      );
      when(collection.where(any, isEqualTo: anyNamed('isEqualTo'))).thenAnswer(
        (call) => query(name, {
          call.positionalArguments.single as String:
              call.namedArguments[#isEqualTo],
        }),
      );
      return collection;
    });
    when(firestore.runTransaction<void>(any)).thenAnswer((call) async {
      final action =
          call.positionalArguments.single as TransactionHandler<void>;
      Future<List<void Function()>> run() async {
        final tx = MockTransaction();
        final pending = <void Function()>[];
        when(tx.get(any)).thenAnswer((call) async {
          if (pending.isNotEmpty) throw StateError('読み取りは書き込みより前に行う');
          final path =
              (call.positionalArguments.single as DocumentReference).path;
          reads.add(path);
          final doc = MockDocumentSnapshot();
          when(doc.exists).thenReturn(rows.containsKey(path));
          when(doc.data())
              .thenReturn(rows[path] == null ? null : Map.of(rows[path]!));
          return doc;
        });
        when(tx.set(any, any)).thenAnswer((call) {
          final path = (call.positionalArguments[0] as DocumentReference).path;
          final data = Map<String, dynamic>.from(
            call.positionalArguments[1] as Map,
          );
          pending.add(() => rows[path] = data);
          return tx;
        });
        when(tx.update(any, any)).thenAnswer((call) {
          final path = (call.positionalArguments[0] as DocumentReference).path;
          final data = Map<String, dynamic>.from(
            call.positionalArguments[1] as Map,
          );
          pending.add(() => rows[path]!.addAll(data));
          return tx;
        });
        when(tx.delete(any)).thenAnswer((call) {
          final path = (call.positionalArguments[0] as DocumentReference).path;
          pending.add(() => rows.remove(path));
          return tx;
        });
        await action(tx);
        return pending;
      }

      var pending = await run();
      if (beforeRetry case final retry?) {
        beforeRetry = null;
        retry();
        pending = await run();
      }
      await beforeCommit?.call();
      if (commitError case final error?) throw error;
      for (final write in pending) {
        write();
      }
      commits++;
    });
  }
  MockDocumentReference reference(String path) {
    final ref = MockDocumentReference();
    when(ref.path).thenReturn(path);
    when(ref.id).thenReturn(path.split('/').last);
    return ref;
  }

  MockQuery query(String collection, Map<String, dynamic> filters) {
    final query = MockQuery();
    when(query.where(any, isEqualTo: anyNamed('isEqualTo'))).thenAnswer(
      (call) => this.query(collection, {
        ...filters,
        call.positionalArguments.single as String:
            call.namedArguments[#isEqualTo],
      }),
    );
    when(query.get()).thenAnswer((_) async {
      final snapshot = MockQuerySnapshot();
      final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final entry in rows.entries) {
        if (!entry.key.startsWith('$collection/') ||
            !filters.entries.every(
              (filter) => entry.value[filter.key] == filter.value,
            )) {
          continue;
        }
        final doc = MockQueryDocumentSnapshot();
        when(doc.id).thenReturn(entry.key.split('/').last);
        final ref = reference(entry.key);
        when(doc.reference).thenReturn(ref);
        when(doc.data()).thenReturn(Map.of(entry.value));
        docs.add(doc);
      }
      when(snapshot.docs).thenReturn(docs);
      return snapshot;
    });
    return query;
  }
}
