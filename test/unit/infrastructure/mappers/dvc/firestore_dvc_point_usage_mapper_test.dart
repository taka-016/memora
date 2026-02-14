import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';
import 'package:memora/infrastructure/mappers/dvc/firestore_dvc_point_usage_mapper.dart';

void main() {
  group('FirestoreDvcPointUsageMapper', () {
    test('エンティティをFirestoreマップへ変換できる', () {
      final usage = DvcPointUsage(
        id: 'usage001',
        groupId: 'group001',
        usageYearMonth: DateTime(2025, 10),
        usedPoint: 60,
        memo: 'ホテル',
      );

      final map = FirestoreDvcPointUsageMapper.toFirestore(usage);

      expect(map['groupId'], 'group001');
      expect(map['usageYearMonth'], isA<Timestamp>());
      expect(map['usedPoint'], 60);
      expect(map['memo'], 'ホテル');
      expect(map['createdAt'], isA<FieldValue>());
    });
  });
}
