import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/group/group_event.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_event_mapper.dart';

import '../../../../helpers/fake_document_snapshot.dart';

void main() {
  group('FirestoreGroupEventMapper', () {
    test('FirestoreドキュメントからGroupEventDtoへ変換できる', () {
      final doc = FakeDocumentSnapshot(
        docId: 'event001',
        data: {
          'groupId': 'group001',
          'type': 'meeting',
          'startDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
          'endDate': Timestamp.fromDate(DateTime(2024, 1, 2)),
        },
      );

      final dto = FirestoreGroupEventMapper.fromFirestore(doc);

      expect(dto.id, 'event001');
      expect(dto.groupId, 'group001');
      expect(dto.type, 'meeting');
      expect(dto.startDate, DateTime(2024, 1, 1));
      expect(dto.endDate, DateTime(2024, 1, 2));
    });

    test('Firestoreの欠損値はデフォルトで補完する', () {
      final doc = FakeDocumentSnapshot(
        docId: 'event002',
        data: {'groupId': 'group002'},
      );

      final dto = FirestoreGroupEventMapper.fromFirestore(doc);

      expect(dto.id, 'event002');
      expect(dto.groupId, 'group002');
      expect(dto.type, '');
      expect(dto.startDate, DateTime.fromMillisecondsSinceEpoch(0));
      expect(dto.endDate, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('GroupEventをFirestoreのMapへ変換できる', () {
      final event = GroupEvent(
        id: 'event003',
        groupId: 'group003',
        type: 'trip',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 2),
      );

      final data = FirestoreGroupEventMapper.toFirestore(event);

      expect(data['groupId'], 'group003');
      expect(data['type'], 'trip');
      expect(data['startDate'], isA<Timestamp>());
      expect(data['endDate'], isA<Timestamp>());
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}
