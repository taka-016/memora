import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/infrastructure/queries/calendar/firestore_calendar_event_watch_query_service.dart';
import 'package:memora/infrastructure/queries/calendar/firestore_calendar_label_watch_query_service.dart';

import '../../../../helpers/test_exception.dart';
import 'firestore_calendar_watch_query_service_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseFirestore>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(),
  MockSpec<Query<Map<String, dynamic>>>(),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(),
  MockSpec<QueryDocumentSnapshot<Map<String, dynamic>>>(),
  MockSpec<DocumentChange<Map<String, dynamic>>>(),
  MockSpec<DocumentReference<Map<String, dynamic>>>(),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(),
])
void main() {
  late MockFirebaseFirestore firestore;
  late MockCollectionReference collection;
  late MockQuery query;
  late MockQuery cancellationQuery;
  late Future<List<Map<String, dynamic>>> Function() cancellationRows;
  late StreamController<QuerySnapshot<Map<String, dynamic>>> source;
  Future<void> flush() => Future<void>(() {});
  MockQueryDocumentSnapshot doc(
    String id, {
    String title = '予定',
    List<String> ids = const [],
  }) {
    final doc = MockQueryDocumentSnapshot();
    when(doc.id).thenReturn(id);
    when(doc.data()).thenReturn({
      'groupId': 'g',
      'title': title,
      'labelId': 'l',
      'labelType': 'custom',
      'textColor': '#FFFFFF',
      'isAllDay': true,
      'startDateTime': Timestamp.fromDate(DateTime.utc(2026, 10, 1)),
      'endDateTime': Timestamp.fromDate(DateTime.utc(2026, 10, 1)),
      'overrideIds': ids,
      'recurrenceRule': ids.isEmpty ? null : 'FREQ=DAILY',
      'name': title,
      'color': '#123ABC',
      'sortOrder': id == 'b' ? 0 : 1,
    });
    return doc;
  }

  void emit(
    List<MockQueryDocumentSnapshot> docs,
    List<(DocumentChangeType, MockQueryDocumentSnapshot)> changes,
  ) {
    final snapshot = MockQuerySnapshot();
    when(snapshot.docs).thenReturn(docs);
    final docChanges = <DocumentChange<Map<String, dynamic>>>[
      for (final (type, doc) in changes)
        (() {
          final change = MockDocumentChange();
          when(change.type).thenReturn(type);
          when(change.doc).thenReturn(doc);
          return change;
        })(),
    ];
    when(snapshot.docChanges).thenReturn(docChanges);
    source.add(snapshot);
  }

  setUp(() {
    firestore = MockFirebaseFirestore();
    collection = MockCollectionReference();
    query = MockQuery();
    source = StreamController<QuerySnapshot<Map<String, dynamic>>>();
    when(firestore.collection(any)).thenReturn(collection);
    when(collection.where('groupId', isEqualTo: 'g')).thenReturn(query);
    when(query.snapshots()).thenAnswer((_) => source.stream);
    cancellationQuery = MockQuery();
    cancellationRows = () async => [];
    final cancellations = MockCollectionReference();
    when(firestore.collection('calendar_event_overrides')).thenReturn(cancellations);
    when(cancellations.where('eventId', isEqualTo: anyNamed('isEqualTo'))).thenReturn(cancellationQuery);
    when(cancellationQuery.where('groupId', isEqualTo: 'g')).thenReturn(cancellationQuery);
    when(cancellationQuery.get()).thenAnswer((_) async {
      final rows = await cancellationRows();
      final result = MockQuerySnapshot();
      when(result.docs).thenReturn([for (final row in rows) (() {
        final value = MockQueryDocumentSnapshot();
        when(value.data()).thenReturn(row);
        return value;
      })()]);
      return result;
    });
    addTearDown(source.close);
  });
  test('共有相手の購読が残っていても監視失敗後の再試行で再接続する', () async {
    final service = FirestoreCalendarEventWatchQueryService(
      firestore: firestore,
    );
    final errors = <Object>[];
    final first = service
        .watchCalendarEventsByGroupId('g')
        .listen((_) {}, onError: errors.add);
    source.addError(TestException('通信失敗'));
    await flush();
    expect(errors, hasLength(1));
    await source.close();
    source = StreamController<QuerySnapshot<Map<String, dynamic>>>();
    final values = <List<dynamic>>[];
    final retry = service
        .watchCalendarEventsByGroupId('g')
        .listen(values.add, onError: errors.add);
    final a = doc('a');
    emit([a], [(DocumentChangeType.added, a)]);
    await flush();
    expect(values.single.single.id, 'a');
    await first.cancel();
    // 古い共有先の破棄で新しい共有先を外さない。
    final thirdValues = <List<dynamic>>[];
    final third = service
        .watchCalendarEventsByGroupId('g')
        .listen(thirdValues.add);
    await flush();
    expect(thirdValues.single.single.id, 'a');
    verify(query.snapshots()).called(2);
    await retry.cancel();
    await third.cancel();
  });

  test('同じグループと期間の監視を共有し後からの購読にも受信済み予定を渡す', () async {
    final service = FirestoreCalendarEventWatchQueryService(
      firestore: firestore,
    );
    final first = <List<dynamic>>[];
    final second = <List<dynamic>>[];
    final a = doc('a');
    final sub = service.watchCalendarEventsByGroupId('g').listen(first.add);
    emit([a], [(DocumentChangeType.added, a)]);
    await flush();
    final another = service
        .watchCalendarEventsByGroupId('g')
        .listen(second.add);
    await flush();
    expect(second.single.single.id, 'a');
    verify(query.snapshots()).called(1);
    await sub.cancel();
    emit([], [(DocumentChangeType.removed, a)]);
    await flush();
    expect(second.last, isEmpty);
    await another.cancel();
    expect(source.hasListener, isFalse);
  });

  test('初回と追加変更削除を反映し変更のない予定の個別回は再取得しない', () async {
    cancellationRows = () async => [{'originalStartDateTime': Timestamp.fromDate(DateTime.utc(2026, 10, 1)), 'isCancelled': true}];
    final values = <List<dynamic>>[];
    final sub = FirestoreCalendarEventWatchQueryService(firestore: firestore)
        .watchCalendarEventsByGroupId('g')
        .listen(values.add);
    addTearDown(sub.cancel);
    final a = doc('a', ids: ['o']);
    final b = doc('b');
    emit([a], [(DocumentChangeType.added, a)]);
    await flush();
    expect(values.last.single.overrides.single.isCancelled, isTrue);
    emit([a, b], [(DocumentChangeType.added, b)]);
    await flush();
    verify(cancellationQuery.get()).called(1);
    final changed = doc('a', title: '変更', ids: ['o']);
    emit([changed, b], [(DocumentChangeType.modified, changed)]);
    await flush();
    expect(values.last.first.title, '変更');
    verify(cancellationQuery.get()).called(1);
    emit([b], [(DocumentChangeType.removed, changed)]);
    await flush();
    expect(values.last.single.id, 'b');
    verify(query.snapshots()).called(1);
  });
  test('個別回取得の前後逆転と削除で古い結果を反映せず解除後も通知しない', () async {
    final pending = Completer<List<Map<String, dynamic>>>();
    cancellationRows = () => pending.future;
    final values = <List<dynamic>>[];
    final sub = FirestoreCalendarEventWatchQueryService(firestore: firestore)
        .watchCalendarEventsByGroupId('g')
        .listen(values.add);
    final old = doc('a', ids: ['o']);
    emit([old], [(DocumentChangeType.added, old)]);
    await flush();
    final newer = doc('a', title: '新しい');
    emit([newer], [(DocumentChangeType.modified, newer)]);
    await flush();
    expect(values.last.single.title, '新しい');
    emit([], [(DocumentChangeType.removed, newer)]);
    await flush();
    pending.complete([{'originalStartDateTime': Timestamp.fromDate(DateTime.utc(2026, 10, 1)), 'isCancelled': true}]);
    await flush();
    expect(values, hasLength(2));
    expect(values.last, isEmpty);
    await sub.cancel();
    expect(source.hasListener, isFalse);
  });
  test('個別回取得失敗を通知し再購読では個別回も再取得する', () async {
    cancellationRows = () async => throw TestException('取得失敗');
    final service = FirestoreCalendarEventWatchQueryService(
      firestore: firestore,
    );
    final errors = <Object>[];
    final sub = service
        .watchCalendarEventsByGroupId('g')
        .listen((_) {}, onError: errors.add);
    final a = doc('a', ids: ['o']);
    emit([a], [(DocumentChangeType.added, a)]);
    await flush();
    expect(errors, hasLength(1));
    await sub.cancel();
    await source.close();
    source = StreamController<QuerySnapshot<Map<String, dynamic>>>();
    cancellationRows = () async => [{'originalStartDateTime': Timestamp.fromDate(DateTime.utc(2026, 10, 1)), 'isCancelled': true}];
    final values = <List<dynamic>>[];
    final retry = service.watchCalendarEventsByGroupId('g').listen(values.add);
    addTearDown(retry.cancel);
    emit([a], [(DocumentChangeType.added, a)]);
    await flush();
    expect(values.last.single.overrides, hasLength(1));
    verify(cancellationQuery.get()).called(2);
  });
  test('色ラベルの追加変更削除と順序を反映し監視エラーを通知する', () async {
    final values = <List<dynamic>>[];
    final errors = <Object>[];
    final sub = FirestoreCalendarLabelWatchQueryService(firestore: firestore)
        .watchCalendarLabelsByGroupId('g')
        .listen(values.add, onError: errors.add);
    addTearDown(sub.cancel);
    final a = doc('a');
    final b = doc('b');
    emit([a, b], []);
    await flush();
    expect(values.last.map((v) => v.id), ['b', 'a']);
    final changed = doc('b', title: '変更');
    emit([changed], []);
    await flush();
    expect(values.last.single.name, '変更');
    source.addError(TestException('監視失敗'));
    await flush();
    expect(errors, hasLength(1));
  });
}
