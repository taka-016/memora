import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/domain/value_objects/route_segment_detail.dart';

void main() {
  group('RouteSegmentDetail', () {
    test('emptyコンストラクタは全フィールドを初期化する', () {
      const detail = RouteSegmentDetail.empty();

      expect(detail.polyline, isEmpty);
      expect(detail.distanceMeters, 0);
      expect(detail.durationSeconds, 0);
      expect(detail.instructions, isEmpty);
    });

    test('copyWithで指定したフィールドだけを更新できる', () {
      const original = RouteSegmentDetail(
        polyline: [Location(latitude: 35.0, longitude: 135.0)],
        distanceMeters: 1000,
        durationSeconds: 600,
        instructions: ['直進してください'],
      );

      final copied = original.copyWith(
        distanceMeters: 1200,
        durationSeconds: 650,
      );

      expect(copied.polyline, equals(original.polyline));
      expect(copied.instructions, equals(original.instructions));
      expect(copied.distanceMeters, 1200);
      expect(copied.durationSeconds, 650);
    });

    test('Equatableのpropsには全フィールドが含まれる', () {
      const detail = RouteSegmentDetail(
        polyline: [Location(latitude: 35.0, longitude: 135.0)],
        distanceMeters: 1000,
        durationSeconds: 600,
        instructions: ['直進してください'],
      );

      expect(detail.props, [
        detail.polyline,
        detail.distanceMeters,
        detail.durationSeconds,
        detail.instructions,
      ]);
    });
  });
}
