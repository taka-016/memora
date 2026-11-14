import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/infrastructure/queries/trip/firestore_location_query_service.dart';

import '../member/firestore_member_query_service_test.mocks.dart';

void main() {
  test('場所のグループ一覧も所属内の旅行IDごとに取得する', () async {
    final db = MockFirebaseFirestore();
    final parents = MockCollectionReference<Map<String, dynamic>>();
    final children = MockCollectionReference<Map<String, dynamic>>();
    final parentQuery = MockQuery<Map<String, dynamic>>();
    final childQuery = MockQuery<Map<String, dynamic>>();
    final parentSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
    final childSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
    final parent = MockQueryDocumentSnapshot<Map<String, dynamic>>();
    when(db.collection('trip_entries')).thenReturn(parents);
    when(db.collection('locations')).thenReturn(children);
    when(parents.where('groupId', isEqualTo: 'g')).thenReturn(parentQuery);
    when(parentQuery.get()).thenAnswer((_) async => parentSnapshot);
    when(parentSnapshot.docs).thenReturn([parent]);
    when(parent.id).thenReturn('trip');
    when(children.where('groupId', isEqualTo: 'g')).thenReturn(childQuery);
    when(childQuery.where('tripId', isEqualTo: 'trip')).thenReturn(childQuery);
    when(childQuery.get()).thenAnswer((_) async => childSnapshot);
    when(childSnapshot.docs).thenReturn([]);
    expect(
      await FirestoreLocationQueryService(firestore: db)
          .getLocationsByGroupId('g'),
      isEmpty,
    );
    verify(childQuery.where('tripId', isEqualTo: 'trip')).called(1);
  });
}
