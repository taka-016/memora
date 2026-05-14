import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/mappers/firestore_mapper_value_parser.dart';

void main() {
  group('FirestoreMapperValueParser', () {
    test('TimestampはUTCのDateTimeとして返す', () {
      final timestamp = Timestamp.fromDate(DateTime(2026, 5, 14, 9, 30));

      final result = FirestoreMapperValueParser.asDateTime(timestamp);

      expect(result, DateTime(2026, 5, 14, 9, 30).toUtc());
      expect(result!.isUtc, isTrue);
    });

    test('DateTimeはUTCへ正規化して返す', () {
      final dateTime = DateTime(2026, 5, 14, 9, 30);

      final result = FirestoreMapperValueParser.asDateTime(dateTime);

      expect(result, dateTime.toUtc());
      expect(result!.isUtc, isTrue);
    });
  });
}
