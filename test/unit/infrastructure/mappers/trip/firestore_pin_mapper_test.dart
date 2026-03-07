import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/entities/trip/pin.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_pin_mapper.dart';

import 'firestore_pin_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('FirestorePinMapper', () {
    test('FirestoreドキュメントからPinDtoへ変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.data()).thenReturn({
        'pinId': 'pin001',
        'tripId': 'trip001',
        'groupId': 'group001',
        'latitude': 35,
        'longitude': 139.5,
        'locationName': '東京駅',
        'visitStartDate': Timestamp.fromDate(DateTime(2025, 5, 1, 10)),
        'visitEndDate': Timestamp.fromDate(DateTime(2025, 5, 1, 11)),
        'visitMemo': '集合',
      });

      final result = FirestorePinMapper.fromFirestore(doc);

      expect(result.pinId, 'pin001');
      expect(result.tripId, 'trip001');
      expect(result.groupId, 'group001');
      expect(result.latitude, 35.0);
      expect(result.longitude, 139.5);
      expect(result.locationName, '東京駅');
      expect(result.visitStartDate, DateTime(2025, 5, 1, 10));
      expect(result.visitEndDate, DateTime(2025, 5, 1, 11));
      expect(result.visitMemo, '集合');
    });

    test('Firestoreの欠損値をデフォルトで変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.data()).thenReturn({});

      final result = FirestorePinMapper.fromFirestore(doc);

      expect(result.pinId, '');
      expect(result.tripId, isNull);
      expect(result.groupId, isNull);
      expect(result.latitude, 0.0);
      expect(result.longitude, 0.0);
      expect(result.locationName, isNull);
      expect(result.visitStartDate, isNull);
      expect(result.visitEndDate, isNull);
      expect(result.visitMemo, isNull);
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
  });
}
