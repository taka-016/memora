import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/queries/trip/firestore_pin_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';

import 'firestore_pin_query_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
void main() {
  group('FirestorePinQueryService', () {
    late FirestorePinQueryService service;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockGroupsCollection;
    late MockCollectionReference<Map<String, dynamic>>
    mockGroupMembersCollection;
    late MockCollectionReference<Map<String, dynamic>> mockPinsCollection;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockGroupsCollection = MockCollectionReference<Map<String, dynamic>>();
      mockGroupMembersCollection =
          MockCollectionReference<Map<String, dynamic>>();
      mockPinsCollection = MockCollectionReference<Map<String, dynamic>>();

      service = FirestorePinQueryService(firestore: mockFirestore);
    });

    test('自分が所属するグループに紐づくピンを取得できる', () async {
      const memberId = 'member123';

      when(mockFirestore.collection('groups')).thenReturn(mockGroupsCollection);
      final mockAdminGroupsQuery = MockQuery<Map<String, dynamic>>();
      when(
        mockGroupsCollection.where('ownerId', isEqualTo: memberId),
      ).thenReturn(mockAdminGroupsQuery);
      final mockAdminGroupsSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      when(
        mockAdminGroupsQuery.get(),
      ).thenAnswer((_) async => mockAdminGroupsSnapshot);
      final mockAdminGroupDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockAdminGroupsSnapshot.docs).thenReturn([mockAdminGroupDoc]);
      when(mockAdminGroupDoc.id).thenReturn('group1');

      when(
        mockFirestore.collection('group_members'),
      ).thenReturn(mockGroupMembersCollection);
      final mockMemberGroupsQuery = MockQuery<Map<String, dynamic>>();
      when(
        mockGroupMembersCollection.where('memberId', isEqualTo: memberId),
      ).thenReturn(mockMemberGroupsQuery);
      final mockMemberGroupsSnapshot =
          MockQuerySnapshot<Map<String, dynamic>>();
      when(
        mockMemberGroupsQuery.get(),
      ).thenAnswer((_) async => mockMemberGroupsSnapshot);
      final mockMemberGroupDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockMemberGroupsSnapshot.docs).thenReturn([mockMemberGroupDoc]);
      when(mockMemberGroupDoc.data()).thenReturn({'groupId': 'group2'});

      when(mockFirestore.collection('pins')).thenReturn(mockPinsCollection);

      final mockGroup1PinsQuery = MockQuery<Map<String, dynamic>>();
      when(
        mockPinsCollection.where('groupId', isEqualTo: 'group1'),
      ).thenReturn(mockGroup1PinsQuery);
      final mockGroup1PinsSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      when(
        mockGroup1PinsQuery.get(),
      ).thenAnswer((_) async => mockGroup1PinsSnapshot);
      final mockGroup1PinDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockGroup1PinsSnapshot.docs).thenReturn([mockGroup1PinDoc]);
      when(mockGroup1PinDoc.data()).thenReturn({
        'pinId': 'pin1',
        'tripId': 'trip1',
        'groupId': 'group1',
        'latitude': 35.0,
        'longitude': 139.0,
        'locationName': '東京駅',
        'visitStartDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'visitEndDate': Timestamp.fromDate(DateTime(2024, 1, 2)),
        'visitMemo': 'メモ1',
      });

      final mockGroup2PinsQuery = MockQuery<Map<String, dynamic>>();
      when(
        mockPinsCollection.where('groupId', isEqualTo: 'group2'),
      ).thenReturn(mockGroup2PinsQuery);
      final mockGroup2PinsSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      when(
        mockGroup2PinsQuery.get(),
      ).thenAnswer((_) async => mockGroup2PinsSnapshot);
      final mockGroup2PinDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockGroup2PinsSnapshot.docs).thenReturn([mockGroup2PinDoc]);
      when(mockGroup2PinDoc.data()).thenReturn({
        'pinId': 'pin2',
        'tripId': 'trip2',
        'groupId': 'group2',
        'latitude': 36.0,
        'longitude': 140.0,
        'locationName': '京都駅',
        'visitStartDate': Timestamp.fromDate(DateTime(2024, 2, 1)),
        'visitEndDate': Timestamp.fromDate(DateTime(2024, 2, 2)),
        'visitMemo': 'メモ2',
      });

      final result = await service.getPinsByMemberId(memberId);

      expect(result, hasLength(2));
      expect(result[0].pinId, 'pin1');
      expect(result[0].groupId, 'group1');
      expect(result[0].visitStartDate, DateTime(2024, 1, 1));
      expect(result[0].visitEndDate, DateTime(2024, 1, 2));
      expect(result[1].pinId, 'pin2');
      expect(result[1].groupId, 'group2');
      expect(result[1].locationName, '京都駅');
    });

    test('例外が発生した場合は空のリストを返す', () async {
      const memberId = 'member123';

      when(
        mockFirestore.collection('groups'),
      ).thenThrow(TestException('Firestore error'));

      final result = await service.getPinsByMemberId(memberId);

      expect(result, isEmpty);
    });
  });
}
