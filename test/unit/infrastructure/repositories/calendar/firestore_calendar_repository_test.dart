import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/infrastructure/repositories/group/firestore_group_repository.dart';
import 'package:memora/infrastructure/queries/calendar/firestore_calendar_event_query_service.dart';
import 'package:memora/application/mappers/calendar/calendar_event_mapper.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:memora/infrastructure/mappers/calendar/firestore_calendar_event_mapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/calendar/calendar_event.dart';
import 'package:memora/domain/entities/calendar/calendar_label.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/calendar/calendar_event_repository.dart';
import 'package:memora/domain/repositories/calendar/calendar_label_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/mappers/calendar/firestore_calendar_label_mapper.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseFirestore>(),
  MockSpec<FirebaseAuth>(),
  MockSpec<Transaction>(),
  MockSpec<WriteBatch>(),
  MockSpec<Query<Map<String, dynamic>>>(),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(),
  MockSpec<QueryDocumentSnapshot<Map<String, dynamic>>>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(),
  MockSpec<DocumentReference<Map<String, dynamic>>>(),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(),
])
import 'firestore_calendar_repository_test.mocks.dart';

typedef _ReadResult = ({CalendarEventDto? event, ValidationException? error});

void main() {
  late MockFirebaseFirestore firestore;
  late MockTransaction transaction;
  late MockDocumentReference labelRef;
  late MockDocumentReference eventRef;
  late MockDocumentReference otherRef;
  late ProviderContainer container;
  late CalendarEventRepository events;
  late CalendarLabelRepository labels;
  late MockDocumentSnapshot eventDoc;
  late MockDocumentSnapshot labelDoc;
  late MockCollectionReference overrideCollection;
  final overrideRefs = <String, MockDocumentReference>{};

  test('Firestoreの文字色を往復し旧ラベルには従来の白黒を補完する', () {
    final doc = MockDocumentSnapshot();
    when(doc.id).thenReturn('label');
    for (final color in ['#FFFFFF', '#123ABC']) {
      final data = {'groupId': 'group', 'name': '全員', 'color': color};
      when(doc.data()).thenReturn(data);
      expect(
        FirestoreCalendarLabelMapper.fromFirestore(doc).textColor,
        color == '#FFFFFF' ? '#000000' : '#FFFFFF',
      );
      when(doc.data())
          .thenReturn({...data, 'textColor': '#Ab12Cd', 'sortOrder': 3});
      expect(
        FirestoreCalendarLabelMapper.fromFirestore(doc).textColor,
        '#Ab12Cd',
      );
      final value = CalendarLabel(
        id: 'label',
        groupId: 'group',
        name: '全員',
        color: color,
        textColor: '#Ab12Cd',
        sortOrder: 3,
      );
      expect(
        FirestoreCalendarLabelMapper.toCreateFirestore(value)['sortOrder'],
        3,
      );
      expect(
        FirestoreCalendarLabelMapper.toCreateFirestore(value)['textColor'],
        '#Ab12Cd',
      );
      expect(
        FirestoreCalendarLabelMapper.toUpdateFirestore(value)['textColor'],
        '#Ab12Cd',
      );
    }
  });
  setUp(() {
    overrideRefs.clear();
    firestore = MockFirebaseFirestore();
    overrideCollection = MockCollectionReference();
    when(firestore.collection('calendar_event_overrides'))
        .thenReturn(overrideCollection);
    when(overrideCollection.doc(any)).thenAnswer((call) {
      final id = call.positionalArguments.single as String;
      return overrideRefs.putIfAbsent(id, () {
        final ref = MockDocumentReference();
        when(ref.id).thenReturn(id);
        return ref;
      });
    });
    transaction = MockTransaction();
    final labelCollection = MockCollectionReference();
    final eventCollection = MockCollectionReference();
    labelRef = MockDocumentReference();
    eventRef = MockDocumentReference();
    otherRef = MockDocumentReference();
    when(firestore.collection('calendar_labels')).thenReturn(labelCollection);
    when(firestore.collection('calendar_events')).thenReturn(eventCollection);
    when(labelCollection.doc('label')).thenReturn(labelRef);
    when(labelCollection.doc('other')).thenReturn(otherRef);
    when(eventCollection.doc(any)).thenReturn(eventRef);
    when(eventRef.id).thenReturn('event');
    eventDoc = MockDocumentSnapshot();
    labelDoc = MockDocumentSnapshot();
    when(eventDoc.exists).thenReturn(true);
    when(eventDoc.data()).thenReturn({'groupId': 'group', 'labelId': 'label'});
    when(labelDoc.exists).thenReturn(true);
    when(labelDoc.data()).thenReturn({'groupId': 'group', 'eventCount': 1});
    when(transaction.get(eventRef)).thenAnswer((_) async => eventDoc);
    when(transaction.get(labelRef)).thenAnswer((_) async => labelDoc);
    when(transaction.get(otherRef)).thenAnswer((_) async => labelDoc);
    when(firestore.runTransaction<void>(any)).thenAnswer(
      (call) async =>
          await (call.positionalArguments[0]
              as Future<void> Function(Transaction))(transaction),
    );
    when(
      firestore.runTransaction<String>(
        argThat(isA<Future<String> Function(Transaction)>()),
      ),
    ).thenAnswer(
      (call) async =>
          await (call.positionalArguments[0]
              as Future<String> Function(Transaction))(transaction),
    );
    when(
      firestore.runTransaction<_ReadResult>(
        argThat(isA<Future<_ReadResult> Function(Transaction)>()),
      ),
    ).thenAnswer(
      (call) async =>
          await (call.positionalArguments[0]
              as Future<_ReadResult> Function(Transaction))(transaction),
    );
    container = ProviderContainer(
      overrides: [
        firebaseFirestoreProvider.overrideWithValue(firestore),
        firebaseAuthProvider.overrideWithValue(MockFirebaseAuth()),
      ],
    );
    events = container.read(
      Provider(
        (ref) => RepositoryFactory.create<CalendarEventRepository>(ref: ref),
      ),
    );
    labels = container.read(
      Provider(
        (ref) => RepositoryFactory.create<CalendarLabelRepository>(ref: ref),
      ),
    );
  });
  tearDown(() => container.dispose());

  CalendarEvent event({String id = ''}) => CalendarEvent(
    id: id,
    groupId: 'group',
    labelId: 'label',
    title: '旅行',
    startDateTime: DateTime.utc(2026, 10, 1, 12, 34, 56, 123, 456),
    endDateTime: DateTime.utc(2026, 10, 3),
    isAllDay: false,
  );

  test('単発変更と維持する個別予定の保存は参照数とともに一括更新する', () async {
    final expected = event(id: 'event');
    when(eventDoc.id).thenReturn('event');
    when(eventDoc.data())
        .thenReturn(FirestoreCalendarEventMapper.toCreateFirestore(expected));
    final extraRef = MockDocumentReference();
    when(extraRef.id).thenReturn('individual');
    final collection = firestore.collection('calendar_events');
    when(collection.doc()).thenReturn(extraRef);
    await events.replaceCalendarEvent(
      expected,
      expected.copyWith(title: '変更'),
      null,
      preservedEvents: [event().copyWith(title: '個別予定')],
    );
    verifyInOrder([
      transaction.get(eventRef),
      transaction.get(labelRef),
      transaction.update(labelRef, argThat(containsPair('eventCount', 2))),
      transaction.update(eventRef, argThat(containsPair('title', '変更'))),
      transaction.set(extraRef, argThat(containsPair('title', '個別予定'))),
    ]);
  });
  test('系列分割は全読取の後に両系列と参照数を一括保存する', () async {
    final original = event(id: 'event')
        .copyWith(recurrenceRule: 'FREQ=DAILY;COUNT=5', timeZone: 'Asia/Tokyo');
    when(eventDoc.id).thenReturn('event');
    when(eventDoc.data())
        .thenReturn(FirestoreCalendarEventMapper.toCreateFirestore(original));
    final expected = CalendarEventMapper.toEntity(
      FirestoreCalendarEventMapper.fromFirestore(eventDoc),
    );
    final nextRef = MockDocumentReference();
    when(nextRef.id).thenReturn('following');
    final collection = firestore.collection('calendar_events');
    when(collection.doc()).thenReturn(nextRef);
    final head = expected.copyWith(recurrenceRule: 'FREQ=DAILY;COUNT=2');
    final tail = expected.copyWith(
      id: '',
      recurrenceRule: 'FREQ=DAILY;COUNT=3',
      startDateTime: expected.startDateTime.add(const Duration(days: 2)),
      endDateTime: expected.endDateTime.add(const Duration(days: 2)),
    );
    await events.replaceCalendarEvent(expected, head, tail);
    verifyInOrder([
      transaction.get(eventRef),
      transaction.get(labelRef),
      transaction.update(labelRef, argThat(containsPair('eventCount', 2))),
      transaction.update(
        eventRef,
        argThat(containsPair('recurrenceRule', 'FREQ=DAILY;COUNT=2')),
      ),
      transaction.set(
        nextRef,
        argThat(containsPair('recurrenceRule', 'FREQ=DAILY;COUNT=3')),
      ),
    ]);
    await expectLater(
      events.replaceCalendarEvent(expected.copyWith(title: '古い内容'), head, tail),
      throwsA(isA<ValidationException>()),
    );
    verifyNever(transaction.set(any, any));
  });

  test('Firestoreでは系列と個別回と各ラベルの参照を同時に保存する', () async {
    final value = event().copyWith(
      recurrenceRule: 'FREQ=DAILY;COUNT=3',
      timeZone: 'Asia/Tokyo',
      overrides: [
        CalendarEventOverride(
          originalStartDateTime: event().startDateTime.add(
            const Duration(days: 1),
          ),
          isCancelled: false,
          title: '移動',
          startDateTime: DateTime.utc(2026, 11, 2),
          endDateTime: DateTime.utc(2026, 11, 3),
          isAllDay: true,
          labelId: 'other',
        ),
      ],
    );
    await events.saveCalendarEvent(value);
    final data =
        verify(transaction.set(eventRef, captureAny)).captured.single
            as Map<String, dynamic>;
    when(eventDoc.id).thenReturn('event');
    when(eventDoc.data()).thenReturn(data);
    final saved = FirestoreCalendarEventMapper.fromFirestore(eventDoc);
    expect(saved.recurrenceRule, value.recurrenceRule);
    expect(saved.timeZone, 'Asia/Tokyo');
    expect(data.containsKey('overrides'), isFalse);
    expect(data.containsKey('cancelledOccurrences'), isFalse);
    final overrideData =
        verify(transaction.set(overrideRefs.values.single, captureAny))
                .captured
                .single
            as Map<String, dynamic>;
    expect(overrideData['eventId'], 'event');
    expect(overrideData['groupId'], 'group');
    expect(overrideData['labelId'], 'other');
    expect(overrideData['isCancelled'], false);
    expect(
      overrideData['startDateTime'],
      Timestamp.fromDate(DateTime.utc(2026, 11, 2)),
    );
    expect(data['overrideIds'], [overrideRefs.keys.single]);
    verify(transaction.update(otherRef, argThat(containsPair('eventCount', 2))))
        .called(1);
  });

  CalendarEvent recurring() => event(id: 'event').copyWith(
    recurrenceRule: 'FREQ=DAILY;COUNT=3',
    timeZone: 'Asia/Tokyo',
    overrides: [
      CalendarEventOverride(
        originalStartDateTime: event().startDateTime.add(
          const Duration(days: 1),
        ),
        isCancelled: true,
      ),
    ],
  );

  Map<String, dynamic> cancellation(CalendarEvent value) => {
    'eventId': value.id,
    'groupId': value.groupId,
    'originalStartDateTime': Timestamp.fromDate(
      value.overrides.single.originalStartDateTime,
    ),
    'isCancelled': true,
    'title': null,
    'labelId': null,
    'startDateTime': null,
    'endDateTime': null,
    'isAllDay': null,
  };

  void stored(CalendarEvent value) {
    when(eventDoc.id).thenReturn('event');
    when(eventDoc.data()).thenReturn({
      ...FirestoreCalendarEventMapper.toCreateFirestore(
        value.copyWith(overrides: []),
      ),
      'overrideIds': ['stored'],
    });
    final ref = overrideCollection.doc('stored');
    final doc = MockDocumentSnapshot();
    when(doc.exists).thenReturn(true);
    when(doc.data()).thenReturn(cancellation(value));
    when(transaction.get(ref)).thenAnswer((_) async => doc);
    when(ref.get()).thenAnswer((_) async => doc);
  }

  Future<List<CalendarEventDto>> readStoredEvents({
    Map<String, dynamic>? snapshotData,
  }) async {
    final query = MockQuery();
    final snapshot = MockQuerySnapshot();
    final doc = MockQueryDocumentSnapshot();
    when(doc.id).thenReturn('event');
    when(doc.data()).thenReturn(snapshotData ?? eventDoc.data()!);
    final collection = firestore.collection('calendar_events');
    when(collection.where('groupId', isEqualTo: 'group')).thenReturn(query);
    when(query.get()).thenAnswer((_) async => snapshot);
    when(snapshot.docs).thenReturn([doc]);
    final result = await FirestoreCalendarEventQueryService(
      firestore: firestore,
    ).getCalendarEventsByGroupId('group');
    return result;
  }

  test('保存済みの埋め込み個別回を読み次回保存で独立コレクションへ移す', () async {
    final change = CalendarEventOverride(
      originalStartDateTime: event().startDateTime,
      isCancelled: false,
      title: '個別変更',
      labelId: 'other',
      isAllDay: true,
      startDateTime: DateTime.utc(2026, 11, 1),
      endDateTime: DateTime.utc(2026, 11, 2),
    );
    final value = recurring().copyWith(
      overrides: [change, recurring().overrides.single],
    );
    when(eventDoc.id).thenReturn('event');
    when(eventDoc.data()).thenReturn({
      ...FirestoreCalendarEventMapper.toCreateFirestore(value),
      'overrides': {
        'other': [
          {
            'originalStartDateTime': Timestamp.fromDate(
              change.originalStartDateTime,
            ),
            'title': change.title,
            'isAllDay': true,
            'startDateTime': Timestamp.fromDate(change.startDateTime!),
            'endDateTime': Timestamp.fromDate(change.endDateTime!),
          },
        ],
      },
      'cancelledOccurrences': [
        Timestamp.fromDate(value.overrides.last.originalStartDateTime),
      ],
    });
    final saved = CalendarEventMapper.toEntity(
      (await readStoredEvents()).single,
    );
    expect(saved.overrides, value.overrides);
    await events.replaceCalendarEvent(saved, saved.copyWith(title: '移行'), null);
    final parent =
        verify(transaction.update(eventRef, captureAny)).captured.single
            as Map<String, dynamic>;
    expect(parent['overrides'], FieldValue.delete());
    expect(parent['cancelledOccurrences'], FieldValue.delete());
    expect(parent['overrideIds'], hasLength(2));
    final rows = verify(transaction.set(any, captureAny)).captured
        .cast<Map<String, dynamic>>();
    expect(
      rows.where((row) => row['isCancelled'] == false).single['labelId'],
      'other',
    );
    expect(
      rows.where((row) => row['isCancelled'] == true).single['title'],
      isNull,
    );
    verifyNever(transaction.update(otherRef, any));
  });

  test('グループ削除は予定に属する個別回を削除してから色ラベルを削除する', () async {
    stored(recurring());
    final event = MockQueryDocumentSnapshot();
    when(event.id).thenReturn('event');
    final label = MockQueryDocumentSnapshot();
    when(label.id).thenReturn('label');
    var labelCount = 1;
    when(labelDoc.data())
        .thenAnswer((_) => {'groupId': 'group', 'eventCount': labelCount});
    when(transaction.update(labelRef, any)).thenAnswer((call) {
      labelCount = (call.positionalArguments[1] as Map)['eventCount'] as int;
      return transaction;
    });
    for (final name in [
      'calendar_events',
      'calendar_labels',
      'group_members',
    ]) {
      final collection = name == 'group_members'
          ? MockCollectionReference()
          : firestore.collection(name);
      when(firestore.collection(name)).thenReturn(collection);
      final query = MockQuery();
      final snapshot = MockQuerySnapshot();
      when(collection.where('groupId', isEqualTo: 'group')).thenReturn(query);
      when(query.get()).thenAnswer((_) async => snapshot);
      when(snapshot.docs).thenReturn(
        name == 'calendar_events'
            ? [event]
            : name == 'calendar_labels'
            ? [label]
            : [],
      );
    }
    final groups = MockCollectionReference();
    final groupRef = MockDocumentReference();
    final batch = MockWriteBatch();
    when(firestore.collection('groups')).thenReturn(groups);
    when(groups.doc('group')).thenReturn(groupRef);
    when(firestore.batch()).thenReturn(batch);
    when(batch.commit()).thenAnswer((_) async {});
    await FirestoreGroupRepository(firestore: firestore).deleteGroup('group');
    verifyInOrder([
      transaction.delete(eventRef),
      transaction.delete(overrideRefs['stored']!),
      transaction.delete(labelRef),
      batch.delete(groupRef),
      batch.commit(),
    ]);
  });

  test('通常の取得で取消しを復元し読取トランザクションを実行しない', () async {
    final value = recurring();
    stored(value);
    final result = await readStoredEvents();
    expect(result.single.overrides, value.overrides);
    verifyNever(firestore.runTransaction(any));
    verify(overrideRefs['stored']!.get()).called(1);
    verifyNever(transaction.get(any));
  });

  test('系列変更で取消しを維持し個別変更の競合も照合する', () async {
    final value = recurring();
    stored(value);
    await events.replaceCalendarEvent(
      value,
      value.copyWith(title: '系列変更'),
      null,
    );
    final data =
        verify(transaction.set(any, captureAny)).captured.single
            as Map<String, dynamic>;
    expect(data['eventId'], 'event');
    expect(data['isCancelled'], true);
    clearInteractions(transaction);
    await expectLater(
      events.replaceCalendarEvent(value.copyWith(overrides: []), value, null),
      throwsA(isA<ValidationException>()),
    );
    verifyNever(transaction.update(any, any));
    verifyNever(transaction.set(any, any));
    verifyNever(transaction.delete(any));
  });

  test('個別変更のリセットと系列削除は独立した個別回も削除する', () async {
    final value = recurring();
    stored(value);
    await events.updateCalendarEvent(value.copyWith(overrides: []));
    verify(transaction.delete(overrideRefs['stored']!)).called(1);
    final data =
        verify(transaction.update(eventRef, captureAny)).captured.single
            as Map<String, dynamic>;
    expect(data['overrideIds'], isEmpty);
    await events.deleteCalendarEvent('event');
    verify(transaction.delete(overrideRefs['stored']!)).called(1);
    verify(transaction.delete(eventRef)).called(1);
  });

  test('系列分割で個別回を後半に移し前半の対象から削除する', () async {
    final value = recurring();
    stored(value);
    final nextRef = MockDocumentReference();
    when(nextRef.id).thenReturn('following');
    final collection = firestore.collection('calendar_events');
    when(collection.doc()).thenReturn(nextRef);
    await events.replaceCalendarEvent(
      value,
      value.copyWith(recurrenceRule: 'FREQ=DAILY;COUNT=1', overrides: []),
      value.copyWith(
        id: '',
        startDateTime: value.startDateTime.add(const Duration(days: 1)),
        endDateTime: value.endDateTime.add(const Duration(days: 1)),
        recurrenceRule: 'FREQ=DAILY;COUNT=2',
      ),
    );
    verify(transaction.delete(overrideRefs['stored']!)).called(1);
    final writes = verify(transaction.set(any, captureAny)).captured
        .cast<Map<String, dynamic>>();
    expect(
      writes
          .where((row) => row['eventId'] == 'following')
          .single['isCancelled'],
      true,
    );
  });

  test('変更前後で異なる複数ラベルを参照する系列を一括更新できる', () async {
    final collection = firestore.collection('calendar_labels');
    for (final id in ['old', 'new1', 'new2']) {
      final ref = MockDocumentReference();
      when(collection.doc(id)).thenReturn(ref);
      when(transaction.get(ref)).thenAnswer((_) async => labelDoc);
    }
    when(eventDoc.data()).thenReturn({
      'groupId': 'group',
      'labelId': 'label',
      'referencedLabelIds': ['label', 'other', 'old'],
    });
    final value = event(id: 'event').copyWith(
      labelId: 'other',
      recurrenceRule: 'FREQ=DAILY;COUNT=3',
      timeZone: 'Asia/Tokyo',
      overrides: [
        for (var day = 1; day <= 2; day++)
          CalendarEventOverride(
            originalStartDateTime: event().startDateTime.add(
              Duration(days: day),
            ),
            isCancelled: false,
            title: '変更',
            startDateTime: event().startDateTime,
            endDateTime: event().endDateTime,
            isAllDay: false,
            labelId: 'new$day',
          ),
      ],
    );
    await events.updateCalendarEvent(value);
    verify(
      transaction.update(eventRef, argThat(containsPair('labelId', 'other'))),
    ).called(1);
    verify(transaction.update(labelRef, argThat(containsPair('eventCount', 0))))
        .called(1);
    verifyNever(transaction.update(otherRef, any));
  });

  test('予定の新規保存は同じグループのラベルを検証し参照数と予定を同時に保存する', () async {
    final id = await events.saveCalendarEvent(event());
    expect(id, 'event');
    verify(transaction.update(labelRef, argThat(containsPair('eventCount', 2))))
        .called(1);
    final data =
        verify(transaction.set(eventRef, captureAny)).captured.single
            as Map<String, dynamic>;
    expect(data['title'], '旅行');
    expect(
      (data['startDateTime'] as Timestamp).toDate().microsecondsSinceEpoch,
      event().startDateTime.microsecondsSinceEpoch,
    );
  });

  test('並び替えは全ラベルのグループを確認して順序だけを一括更新する', () async {
    await labels.reorderCalendarLabels('group', ['other', 'label']);
    final first =
        verify(transaction.update(otherRef, captureAny)).captured.single
            as Map<String, dynamic>;
    final last =
        verify(transaction.update(labelRef, captureAny)).captured.single
            as Map<String, dynamic>;
    expect(first['sortOrder'], 0);
    expect(last['sortOrder'], 1);
    expect(first.keys.toSet(), {'sortOrder', 'updatedAt'});
    expect(last.keys.toSet(), {'sortOrder', 'updatedAt'});
  });
  test('並び替えに別グループが混ざると更新を一件も書き込まない', () async {
    final foreign = MockDocumentSnapshot();
    when(foreign.exists).thenReturn(true);
    when(foreign.data()).thenReturn({'groupId': 'foreign'});
    when(transaction.get(otherRef)).thenAnswer((_) async => foreign);
    await expectLater(
      labels.reorderCalendarLabels('group', ['label', 'other']),
      throwsA(isA<ValidationException>()),
    );
    verifyNever(transaction.update(any, any));
  });
  test('別グループのラベルを拒否しトランザクションに書き込みを残さない', () async {
    when(labelDoc.data())
        .thenReturn({'groupId': 'other-group', 'eventCount': 1});
    await expectLater(
      events.saveCalendarEvent(event()),
      throwsA(isA<ValidationException>()),
    );
    verifyNever(transaction.set(any, any));
    verifyNever(transaction.update(any, any));
  });

  test('ラベルの付け替えと削除で旧ラベルと新ラベルの参照数を同時に更新する', () async {
    await events.updateCalendarEvent(
      event(id: 'event').copyWith(labelId: 'other'),
    );
    verify(transaction.update(labelRef, argThat(containsPair('eventCount', 0))))
        .called(1);
    verify(transaction.update(otherRef, argThat(containsPair('eventCount', 2))))
        .called(1);
    await events.deleteCalendarEvent('event');
    verify(transaction.delete(eventRef)).called(1);
    verify(transaction.update(labelRef, argThat(containsPair('eventCount', 0))))
        .called(1);
  });

  test('使用中ラベルの削除とグループ変更を拒否し名前と色だけの変更を許可する', () async {
    await expectLater(
      labels.deleteCalendarLabel('label'),
      throwsA(isA<ValidationException>()),
    );
    await expectLater(
      labels.saveCalendarLabel(
        CalendarLabel(
          id: 'label',
          groupId: 'other',
          name: '全員',
          color: '#FFFFFF',
        ),
      ),
      throwsA(isA<ValidationException>()),
    );
    await labels.saveCalendarLabel(
      CalendarLabel(
        id: 'label',
        groupId: 'group',
        name: '全員',
        color: '#FFFFFF',
      ),
    );
    final data =
        verify(transaction.update(labelRef, captureAny)).captured.single
            as Map<String, dynamic>;
    expect(data['name'], '全員');
    expect(data['color'], '#FFFFFF');
    expect(data.containsKey('eventCount'), isFalse);
  });
}
