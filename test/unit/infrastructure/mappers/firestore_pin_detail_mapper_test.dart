import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/entities/pin_detail.dart';
import 'package:memora/infrastructure/mappers/firestore_pin_detail_mapper.dart';

import 'firestore_pin_detail_mapper_test.mocks.dart';

@GenerateMocks([QueryDocumentSnapshot])
void main() {
  group('FirestorePinDetailMapper', () {
    test('FirestoreのDocumentSnapshotからPinDetailへ変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('pinDetail001');
      when(mockDoc.data()).thenReturn({
        'pinId': 'pin-001',
        'name': '東京スカイツリー観光',
        'startDate': Timestamp.fromDate(DateTime(2024, 1, 1, 10)),
        'endDate': Timestamp.fromDate(DateTime(2024, 1, 1, 12)),
        'memo': '展望台まで登る',
      });

      final pinDetail = FirestorePinDetailMapper.fromFirestore(mockDoc);

      expect(pinDetail.pinId, 'pin-001');
      expect(pinDetail.name, '東京スカイツリー観光');
      expect(pinDetail.startDate, DateTime(2024, 1, 1, 10));
      expect(pinDetail.endDate, DateTime(2024, 1, 1, 12));
      expect(pinDetail.memo, '展望台まで登る');
    });

    test('nullableなフィールドがnullの場合でも変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('pinDetail002');
      when(mockDoc.data()).thenReturn({'pinId': 'pin-002'});

      final pinDetail = FirestorePinDetailMapper.fromFirestore(mockDoc);

      expect(pinDetail.pinId, 'pin-002');
      expect(pinDetail.name, isNull);
      expect(pinDetail.startDate, isNull);
      expect(pinDetail.endDate, isNull);
      expect(pinDetail.memo, isNull);
    });

    test('Firestoreのデータが不足している場合はデフォルト値に変換される', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('pinDetail003');
      when(mockDoc.data()).thenReturn({});

      final pinDetail = FirestorePinDetailMapper.fromFirestore(mockDoc);

      expect(pinDetail.pinId, '');
      expect(pinDetail.name, isNull);
      expect(pinDetail.startDate, isNull);
      expect(pinDetail.endDate, isNull);
      expect(pinDetail.memo, isNull);
    });

    test('PinDetailエンティティからFirestoreのMapへ変換できる', () {
      final pinDetail = PinDetail(
        pinId: 'pin-detail-001',
        name: '浅草寺参拝',
        startDate: DateTime(2024, 2, 1, 9, 30),
        endDate: DateTime(2024, 2, 1, 11, 0),
        memo: 'お参りと写真撮影',
      );

      final map = FirestorePinDetailMapper.toFirestore(pinDetail);

      expect(map['pinId'], 'pin-detail-001');
      expect(map['name'], '浅草寺参拝');
      expect(map['startDate'], isA<Timestamp>());
      expect(map['endDate'], isA<Timestamp>());
      expect(map['memo'], 'お参りと写真撮影');
      expect(map['createdAt'], isA<FieldValue>());
    });

    test('オプショナルプロパティがnullでもFirestoreのMapへ変換できる', () {
      final pinDetail = PinDetail(pinId: 'pin-detail-002');

      final map = FirestorePinDetailMapper.toFirestore(pinDetail);

      expect(map['pinId'], 'pin-detail-002');
      expect(map['name'], isNull);
      expect(map['startDate'], isNull);
      expect(map['endDate'], isNull);
      expect(map['memo'], isNull);
      expect(map['createdAt'], isA<FieldValue>());
    });

    test('必須項目のみのPinDetailからFirestoreのMapへ変換できる', () {
      final pinDetail = PinDetail(pinId: 'pin-detail-003', name: '新宿散策');

      final map = FirestorePinDetailMapper.toFirestore(pinDetail);

      expect(map['pinId'], 'pin-detail-003');
      expect(map['name'], '新宿散策');
      expect(map['startDate'], isNull);
      expect(map['endDate'], isNull);
      expect(map['memo'], isNull);
      expect(map['createdAt'], isA<FieldValue>());
    });

    test('日時のみ設定されたPinDetailからFirestoreのMapへ変換できる', () {
      final pinDetail = PinDetail(
        pinId: 'pin-detail-004',
        startDate: DateTime(2024, 3, 15, 14, 30),
        endDate: DateTime(2024, 3, 15, 16, 0),
      );

      final map = FirestorePinDetailMapper.toFirestore(pinDetail);

      expect(map['pinId'], 'pin-detail-004');
      expect(map['name'], isNull);
      expect(map['startDate'], isA<Timestamp>());
      expect(map['endDate'], isA<Timestamp>());
      expect(map['memo'], isNull);
      expect(map['createdAt'], isA<FieldValue>());
    });
  });
}
