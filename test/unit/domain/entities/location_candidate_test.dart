import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/location_candidate.dart';

void main() {
  group('LocationCandidate', () {
    test('インスタンス生成が正しく行われる', () {
      final candidate = LocationCandidate(
        name: '東京タワー',
        address: '東京都港区芝公園4-2-8',
        latitude: 35.6586,
        longitude: 139.7454,
      );
      expect(candidate.name, '東京タワー');
      expect(candidate.address, '東京都港区芝公園4-2-8');
      expect(candidate.latitude, 35.6586);
      expect(candidate.longitude, 139.7454);
    });
  });
}
