import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/queries/calendar/calendar_label_query_service.dart';
import 'package:memora/application/usecases/calendar/delete_calendar_label_usecase.dart';
import 'package:memora/application/usecases/calendar/get_calendar_events_usecase.dart';
import 'package:memora/application/usecases/calendar/get_calendar_labels_usecase.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/infrastructure/queries/calendar/firestore_calendar_event_query_service.dart';
import 'package:memora/infrastructure/repositories/calendar/firestore_calendar_label_repository.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifier.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/test_exception.dart';
import 'isolated_label_deletion_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
  DocumentReference,
  DocumentSnapshot,
  Transaction,
  CalendarLabelQueryService,
])
void main() {
  late ProviderContainer container;
  late MockTransaction transaction;
  late MockDocumentReference<Map<String, dynamic>> labelRef;
  late MockDocumentSnapshot<Map<String, dynamic>> labelDoc;
  late MockFirebaseFirestore firestore;
  const label = CalendarLabelDto(
    id: 'label',
    groupId: 'group',
    name: '全員',
    color: '#123ABC',
  );
  final provider = calendarNotifierProvider('group');

  setUp(() {
    firestore = MockFirebaseFirestore();
    transaction = MockTransaction();
    labelRef = MockDocumentReference<Map<String, dynamic>>();
    labelDoc = MockDocumentSnapshot<Map<String, dynamic>>();
    final labelCollection = MockCollectionReference<Map<String, dynamic>>();
    final eventCollection = MockCollectionReference<Map<String, dynamic>>();
    final query = MockQuery<Map<String, dynamic>>();
    final snapshot = MockQuerySnapshot<Map<String, dynamic>>();
    final invalid = MockQueryDocumentSnapshot<Map<String, dynamic>>();
    when(firestore.collection('calendar_labels')).thenReturn(labelCollection);
    when(firestore.collection('calendar_events')).thenReturn(eventCollection);
    when(labelCollection.doc('label')).thenReturn(labelRef);
    when(eventCollection.where('groupId', isEqualTo: 'group'))
        .thenReturn(query);
    when(query.get()).thenAnswer((_) async => snapshot);
    when(snapshot.docs).thenReturn([invalid]);
    when(invalid.id).thenReturn('invalid');
    when(invalid.data()).thenReturn({
      'groupId': 'group',
      'labelId': 'label',
      'title': '不正な系列',
      'startDateTime': Timestamp.fromDate(DateTime.utc(2026)),
      'endDateTime': Timestamp.fromDate(DateTime.utc(2026)),
      'isAllDay': true,
      'recurrenceRule': 'x',
    });
    when(labelDoc.exists).thenReturn(true);
    when(labelDoc.data()).thenReturn({'groupId': 'group', 'eventCount': 1});
    when(transaction.get(labelRef)).thenAnswer((_) async => labelDoc);
    when(firestore.runTransaction<void>(any)).thenAnswer((call) async {
      await (call.positionalArguments[0] as Future<void> Function(Transaction))(
        transaction,
      );
    });
    final labels = MockCalendarLabelQueryService();
    when(labels.getCalendarLabelsByGroupId('group'))
        .thenAnswer((_) async => [label]);
    final repository = FirestoreCalendarLabelRepository(firestore: firestore);
    container = ProviderContainer(
      overrides: [
        getCalendarEventsUsecaseProvider.overrideWithValue(
          GetCalendarEventsUsecase(
            FirestoreCalendarEventQueryService(
              firestore: firestore,
              ensureMembership: (_) async {},
            ),
          ),
        ),
        getCalendarLabelsUsecaseProvider.overrideWithValue(
          GetCalendarLabelsUsecase(labels),
        ),
        deleteCalendarLabelUsecaseProvider.overrideWithValue(
          DeleteCalendarLabelUsecase(repository),
        ),
      ],
    );
    container.listen(provider, (_, _) {});
  });
  tearDown(() => container.dispose());

  test('不正予定を隔離しても永続化層の使用中理由を表示しラベルを保持する', () async {
    final notifier = container.read(provider.notifier);
    await notifier.load();
    expect(container.read(provider).loadError, isEmpty);
    expect(container.read(provider).events, isEmpty);
    for (var attempt = 0; attempt < 2; attempt++) {
      expect(await notifier.deleteLabel('label'), isFalse);
      expect(container.read(provider).mutationError, '使用中の色ラベルは削除できません');
      expect(container.read(provider).isSaving, isFalse);
      expect(container.read(provider).labels, [label]);
    }
    verifyNever(transaction.delete(labelRef));
  });

  test('通信失敗は使用中エラーに変換せず再試行を案内する', () async {
    final notifier = container.read(provider.notifier);
    await notifier.load();
    when(firestore.runTransaction<void>(any))
        .thenAnswer((_) async => throw TestException('通信失敗'));
    expect(await notifier.deleteLabel('label'), isFalse);
    expect(container.read(provider).mutationError, '保存できませんでした。再試行してください');
    verifyNever(transaction.delete(labelRef));
  });
}
