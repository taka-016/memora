import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/queries/calendar/firestore_calendar_event_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'firestore_calendar_event_query_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
void main() {
  final start = DateTime.utc(2026, 10, 4, 9);
  Map<String, dynamic> eventData() => {
    'groupId': 'group',
    'labelId': 'label',
    'title': '予定',
    'startDateTime': Timestamp.fromDate(start),
    'endDateTime': Timestamp.fromDate(start.add(const Duration(hours: 1))),
    'isAllDay': false,
  };
  MockQueryDocumentSnapshot<Map<String, dynamic>> document(
    String id,
    Map<String, dynamic> data,
  ) {
    final doc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
    when(doc.id).thenReturn(id);
    when(doc.data()).thenReturn(data);
    return doc;
  }

  late MockFirebaseFirestore firestore;
  late MockQuery<Map<String, dynamic>> query;
  late MockQuerySnapshot<Map<String, dynamic>> snapshot;
  late FirestoreCalendarEventQueryService service;
  setUp(() {
    firestore = MockFirebaseFirestore();
    final collection = MockCollectionReference<Map<String, dynamic>>();
    query = MockQuery<Map<String, dynamic>>();
    snapshot = MockQuerySnapshot<Map<String, dynamic>>();
    when(firestore.collection('calendar_events')).thenReturn(collection);
    when(collection.where('groupId', isEqualTo: 'group')).thenReturn(query);
    when(query.get()).thenAnswer((_) async => snapshot);
    service = FirestoreCalendarEventQueryService(
      firestore: firestore,
      ensureMembership: (_) async {},
    );
  });

  final invalidCases = <String, Map<String, dynamic>>{
    '不正な繰り返しルール': {'recurrenceRule': 'x'},
    'UNTILの時刻が不正': {'recurrenceRule': 'FREQ=DAILY;UNTIL=20261004T096000Z'},
    '上書きの要素型が不正': {
      'overrides': {
        'label': [1],
      },
    },
    'キャンセルの要素型が不正': {
      'cancelledOccurrences': [1],
    },
    '存在しないタイムゾーン': {'timeZone': 'Invalid/Zone'},
    '系列に存在しない個別回': {
      'cancelledOccurrences': [
        Timestamp.fromDate(start.add(const Duration(minutes: 30))),
      ],
    },
    '重複した個別回': {
      'cancelledOccurrences': [
        Timestamp.fromDate(start),
        Timestamp.fromDate(start),
      ],
    },
  };
  for (final entry in invalidCases.entries) {
    test('${entry.key}の予定だけを除外して正常な単発と系列を取得できる', () async {
      final recurring = {
        ...eventData(),
        'recurrenceRule': 'FREQ=DAILY;COUNT=2',
        'timeZone': 'Asia/Tokyo',
      };
      final docs = [
        document('single', eventData()),
        document('invalid', {...recurring, ...entry.value}),
        document('series', recurring),
      ];
      when(snapshot.docs).thenReturn(docs);

      final result = await service.getCalendarEventsByGroupId('group');

      expect(result.map((event) => event.id), ['single', 'series']);
      expect(result.last.recurrenceRule, 'FREQ=DAILY;COUNT=2');
      verify(query.get()).called(1);
    });
  }

  test('通信失敗を不正データとして握りつぶさず再取得可能なエラーにする', () async {
    final error = TestException('通信失敗');
    when(query.get()).thenAnswer((_) async => throw error);
    await expectLater(
      service.getCalendarEventsByGroupId('group'),
      throwsA(same(error)),
    );
  });

  test('所属確認失敗を伝播し予定を取得しない', () async {
    final error = TestException('所属確認失敗');
    service = FirestoreCalendarEventQueryService(
      firestore: firestore,
      ensureMembership: (_) async => throw error,
    );
    await expectLater(
      service.getCalendarEventsByGroupId('group'),
      throwsA(same(error)),
    );
    verifyNever(query.get());
  });
}
