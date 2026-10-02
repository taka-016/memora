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
    when(firestore.runTransaction<String>(any)).thenAnswer(
      (call) async =>
          await (call.positionalArguments[0]
              as Future<String> Function(Transaction))(transaction),
    );
    when(firestore.runTransaction<void>(any)).thenAnswer(
      (call) async =>
          await (call.positionalArguments[0]
              as Future<void> Function(Transaction))(transaction),
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
