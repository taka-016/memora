import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/member/member_event.dart';
import 'package:memora/infrastructure/mappers/member/firestore_member_event_mapper.dart';

import '../../../../helpers/fake_document_snapshot.dart';

void main() {
  group('FirestoreMemberEventMapper', () {
    test('FirestoreドキュメントからMemberEventDtoへ変換できる', () {
      final doc = FakeDocumentSnapshot(
        docId: 'event001',
        data: {
          'memberId': 'member001',
          'type': 'training',
          'startDate': Timestamp.fromDate(DateTime(2024, 4, 1)),
          'endDate': Timestamp.fromDate(DateTime(2024, 4, 2)),
        },
      );

      final dto = FirestoreMemberEventMapper.fromFirestore(doc);

      expect(dto.id, 'event001');
      expect(dto.memberId, 'member001');
      expect(dto.type, 'training');
      expect(dto.startDate, DateTime(2024, 4, 1));
      expect(dto.endDate, DateTime(2024, 4, 2));
    });

    test('Firestoreの欠損値はデフォルトで補完する', () {
      final doc = FakeDocumentSnapshot(
        docId: 'event002',
        data: {'memberId': 'member002'},
      );

      final dto = FirestoreMemberEventMapper.fromFirestore(doc);

      expect(dto.id, 'event002');
      expect(dto.memberId, 'member002');
      expect(dto.type, '');
      expect(dto.startDate, DateTime.fromMillisecondsSinceEpoch(0));
      expect(dto.endDate, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('MemberEventをFirestoreのMapへ変換できる', () {
      final memberEvent = MemberEvent(
        id: 'event003',
        memberId: 'member003',
        type: 'meeting',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 2),
      );

      final data = FirestoreMemberEventMapper.toFirestore(memberEvent);

      expect(data['memberId'], 'member003');
      expect(data['type'], 'meeting');
      expect(data['startDate'], isA<Timestamp>());
      expect(data['endDate'], isA<Timestamp>());
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}
