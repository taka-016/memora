import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/value_objects/location_candidate.dart';
import 'package:memora/domain/value_objects/location.dart';

void main() {
  group('LocationCandidate', () {
    test('インスタンス生成が正しく行われる', () {
      final candidate = LocationCandidate(
        name: '東京タワー',
        address: '東京都港区芝公園4-2-8',
        location: const Location(latitude: 35.6586, longitude: 139.7454),
      );
      expect(candidate.name, '東京タワー');
      expect(candidate.address, '東京都港区芝公園4-2-8');
      expect(candidate.location.latitude, 35.6586);
      expect(candidate.location.longitude, 139.7454);
    });

    test('同じプロパティを持つインスタンス同士は等価である', () {
      final candidate1 = LocationCandidate(
        name: '東京タワー',
        address: '東京都港区芝公園4-2-8',
        location: const Location(latitude: 35.6586, longitude: 139.7454),
      );
      final candidate2 = LocationCandidate(
        name: '東京タワー',
        address: '東京都港区芝公園4-2-8',
        location: const Location(latitude: 35.6586, longitude: 139.7454),
      );
      expect(candidate1, equals(candidate2));
    });

    test('異なるプロパティを持つインスタンス同士は等価でない', () {
      final candidate1 = LocationCandidate(
        name: '東京タワー',
        address: '東京都港区芝公園4-2-8',
        location: const Location(latitude: 35.6586, longitude: 139.7454),
      );
      final candidate2 = LocationCandidate(
        name: 'スカイツリー',
        address: '東京都墨田区押上1-1-2',
        location: const Location(latitude: 35.7101, longitude: 139.8107),
      );
      expect(candidate1, isNot(equals(candidate2)));
    });
  });
}
