import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/domain/entities/pin_detail.dart';
import 'package:memora/infrastructure/mappers/firestore_pin_mapper.dart';

import 'firestore_pin_mapper_test.mocks.dart';

@GenerateMocks([QueryDocumentSnapshot])
void main() {
  group('FirestorePinMapper', () {
    test('FirestoreのDocumentSnapshotからPinへ変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.data()).thenReturn({
        'pinId': 'pin-doc-001',
        'tripId': 'trip001',
        'groupId': 'group001',
        'latitude': 35.681236,
        'longitude': 139.767125,
        'locationName': '東京駅',
        'visitStartDate': Timestamp.fromDate(DateTime(2024, 1, 1, 10)),
        'visitEndDate': Timestamp.fromDate(DateTime(2024, 1, 1, 12)),
        'visitMemo': '集合場所',
      });

      final pin = FirestorePinMapper.fromFirestore(mockDoc);

      expect(pin.pinId, 'pin-doc-001');
      expect(pin.tripId, 'trip001');
      expect(pin.groupId, 'group001');
      expect(pin.latitude, 35.681236);
      expect(pin.longitude, 139.767125);
      expect(pin.locationName, '東京駅');
      expect(pin.visitStartDate, DateTime(2024, 1, 1, 10));
      expect(pin.visitEndDate, DateTime(2024, 1, 1, 12));
      expect(pin.visitMemo, '集合場所');
    });

    test('nullableなフィールドがnullの場合でも変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.data()).thenReturn({
        'pinId': 'pin-doc-002',
        'tripId': 'trip002',
        'groupId': 'group002',
        'latitude': 34.701909,
        'longitude': 135.494977,
      });

      final pin = FirestorePinMapper.fromFirestore(mockDoc);

      expect(pin.pinId, 'pin-doc-002');
      expect(pin.tripId, 'trip002');
      expect(pin.groupId, 'group002');
      expect(pin.latitude, 34.701909);
      expect(pin.longitude, 135.494977);
      expect(pin.locationName, isNull);
      expect(pin.visitStartDate, isNull);
      expect(pin.visitEndDate, isNull);
      expect(pin.visitMemo, isNull);
    });

    test('Firestoreのデータが不足している場合はデフォルト値に変換される', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.data()).thenReturn({});

      final pin = FirestorePinMapper.fromFirestore(mockDoc);

      expect(pin.pinId, '');
      expect(pin.tripId, '');
      expect(pin.groupId, '');
      expect(pin.latitude, 0.0);
      expect(pin.longitude, 0.0);
      expect(pin.locationName, isNull);
      expect(pin.visitStartDate, isNull);
      expect(pin.visitEndDate, isNull);
      expect(pin.visitMemo, isNull);
    });

    test('PinエンティティからFirestoreのMapへ変換できる', () {
      final pin = Pin(
        pinId: 'pin-entity-001',
        tripId: 'trip-entity-001',
        groupId: 'group-entity-001',
        latitude: 34.701909,
        longitude: 135.494977,
        locationName: '大阪駅',
        visitStartDate: DateTime(2024, 2, 1, 9, 30),
        visitEndDate: DateTime(2024, 2, 1, 11, 0),
        visitMemo: '観光開始',
      );

      final map = FirestorePinMapper.toFirestore(pin);

      expect(map['pinId'], 'pin-entity-001');
      expect(map['tripId'], 'trip-entity-001');
      expect(map['groupId'], 'group-entity-001');
      expect(map['latitude'], 34.701909);
      expect(map['longitude'], 135.494977);
      expect(map['locationName'], '大阪駅');
      expect(map['visitStartDate'], isA<Timestamp>());
      expect(map['visitEndDate'], isA<Timestamp>());
      expect(map['visitMemo'], '観光開始');
      expect(map['createdAt'], isA<FieldValue>());
    });

    test('オプショナルプロパティがnullでもFirestoreのMapへ変換できる', () {
      final pin = Pin(
        pinId: 'pin-entity-002',
        tripId: 'trip-entity-002',
        groupId: 'group-entity-002',
        latitude: 26.2125,
        longitude: 127.6811,
      );

      final map = FirestorePinMapper.toFirestore(pin);

      expect(map['pinId'], 'pin-entity-002');
      expect(map['tripId'], 'trip-entity-002');
      expect(map['groupId'], 'group-entity-002');
      expect(map['latitude'], 26.2125);
      expect(map['longitude'], 127.6811);
      expect(map['locationName'], isNull);
      expect(map['visitStartDate'], isNull);
      expect(map['visitEndDate'], isNull);
      expect(map['visitMemo'], isNull);
      expect(map['createdAt'], isA<FieldValue>());
    });

    test('空文字列を含むPinからFirestoreのMapへ変換できる', () {
      final pin = Pin(
        pinId: '',
        tripId: '',
        groupId: '',
        latitude: 0.0,
        longitude: 0.0,
      );

      final map = FirestorePinMapper.toFirestore(pin);

      expect(map['pinId'], '');
      expect(map['tripId'], '');
      expect(map['groupId'], '');
      expect(map['latitude'], 0.0);
      expect(map['longitude'], 0.0);
      expect(map['locationName'], isNull);
      expect(map['visitStartDate'], isNull);
      expect(map['visitEndDate'], isNull);
      expect(map['visitMemo'], isNull);
      expect(map['createdAt'], isA<FieldValue>());
    });

    test('detailsパラメータを指定した場合にPinに詳細予定が含まれる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.data()).thenReturn({
        'pinId': 'pin-doc-007',
        'tripId': 'trip007',
        'groupId': 'group007',
        'latitude': 35.681236,
        'longitude': 139.767125,
        'locationName': '東京駅',
        'visitStartDate': Timestamp.fromDate(DateTime(2024, 1, 1, 10)),
        'visitEndDate': Timestamp.fromDate(DateTime(2024, 1, 1, 12)),
        'visitMemo': '集合場所',
      });

      final details = [
        PinDetail(
          pinId: 'pin-doc-007',
          name: '詳細1',
          startDate: DateTime(2024, 1, 1, 10, 30),
          endDate: DateTime(2024, 1, 1, 11),
          memo: 'メモ1',
        ),
        PinDetail(
          pinId: 'pin-doc-007',
          name: '詳細2',
          startDate: DateTime(2024, 1, 1, 11),
          endDate: DateTime(2024, 1, 1, 11, 30),
          memo: 'メモ2',
        ),
      ];

      final pin = FirestorePinMapper.fromFirestore(mockDoc, details: details);

      expect(pin.details, hasLength(2));
      expect(pin.details[0].name, '詳細1');
      expect(pin.details[0].startDate, DateTime(2024, 1, 1, 10, 30));
      expect(pin.details[1].name, '詳細2');
      expect(pin.details[1].startDate, DateTime(2024, 1, 1, 11));
    });

    test('detailsパラメータを指定しない場合は空のリストになる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.data()).thenReturn({
        'pinId': 'pin-doc-008',
        'tripId': 'trip008',
        'groupId': 'group008',
        'latitude': 35.681236,
        'longitude': 139.767125,
      });

      final pin = FirestorePinMapper.fromFirestore(mockDoc);

      expect(pin.details, isEmpty);
    });
  });
}
