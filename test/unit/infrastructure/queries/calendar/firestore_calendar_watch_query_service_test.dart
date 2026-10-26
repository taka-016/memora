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
    addTearDown(source.close);
  });
  test('初回と追加変更削除を反映し変更のない予定の個別回は再取得しない', () async {
    final overrides = MockCollectionReference();
    final ref = MockDocumentReference();
    final override = MockDocumentSnapshot();
    when(firestore.collection('calendar_event_overrides'))
        .thenReturn(overrides);
    when(overrides.doc('o')).thenReturn(ref);
    when(override.data()).thenReturn({
      'eventId': 'a',
      'groupId': 'g',
      'originalStartDateTime': Timestamp.fromDate(DateTime.utc(2026, 10, 1)),
      'isCancelled': true,
    });
    when(ref.get()).thenAnswer((_) async => override);
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
    verify(ref.get()).called(1);
    final changed = doc('a', title: '変更', ids: ['o']);
    emit([changed, b], [(DocumentChangeType.modified, changed)]);
    await flush();
    expect(values.last.first.title, '変更');
    verify(ref.get()).called(1);
    emit([b], [(DocumentChangeType.removed, changed)]);
    await flush();
    expect(values.last.single.id, 'b');
    verify(query.snapshots()).called(1);
  });
  test('個別回取得の前後逆転と削除で古い結果を反映せず解除後も通知しない', () async {
    final overrides = MockCollectionReference();
    final ref = MockDocumentReference();
    when(firestore.collection('calendar_event_overrides'))
        .thenReturn(overrides);
    when(overrides.doc('o')).thenReturn(ref);
    final pending = Completer<DocumentSnapshot<Map<String, dynamic>>>();
    when(ref.get()).thenAnswer((_) => pending.future);
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
    final override = MockDocumentSnapshot();
    when(override.data()).thenReturn({
      'eventId': 'a',
      'groupId': 'g',
      'originalStartDateTime': Timestamp.fromDate(DateTime.utc(2026, 10, 1)),
      'isCancelled': true,
    });
    pending.complete(override);
    await flush();
    expect(values, hasLength(2));
    expect(values.last, isEmpty);
    await sub.cancel();
    expect(source.hasListener, isFalse);
  });
  test('個別回取得失敗を通知し再購読では個別回も再取得する', () async {
    final overrides = MockCollectionReference();
    final ref = MockDocumentReference();
    when(firestore.collection('calendar_event_overrides'))
        .thenReturn(overrides);
    when(overrides.doc('o')).thenReturn(ref);
    when(ref.get()).thenThrow(TestException('取得失敗'));
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
    final override = MockDocumentSnapshot();
    when(override.data()).thenReturn({
      'eventId': 'a',
      'groupId': 'g',
      'originalStartDateTime': Timestamp.fromDate(DateTime.utc(2026, 10, 1)),
      'isCancelled': true,
    });
    when(ref.get()).thenAnswer((_) async => override);
    final values = <List<dynamic>>[];
    final retry = service.watchCalendarEventsByGroupId('g').listen(values.add);
    addTearDown(retry.cancel);
    emit([a], [(DocumentChangeType.added, a)]);
    await flush();
    expect(values.last.single.overrides, hasLength(1));
    verify(ref.get()).called(2);
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
