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
  MockSpec<CollectionReference<Map<String, dynamic>>>(),
  MockSpec<DocumentReference<Map<String, dynamic>>>(),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(),
])
import 'firestore_calendar_repository_test.mocks.dart';

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
    firestore = MockFirebaseFirestore();
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
    expect(saved.overrides, value.overrides);
    verify(transaction.update(otherRef, argThat(containsPair('eventCount', 2))))
        .called(1);
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
