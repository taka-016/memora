import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/location/get_current_location_usecase.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/domain/services/current_location_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'get_current_location_usecase_test.mocks.dart';

@GenerateMocks([CurrentLocationService])
void main() {
  group('GetCurrentLocationUsecase', () {
    late MockCurrentLocationService mockCurrentLocationService;
    late GetCurrentLocationUsecase usecase;

    setUp(() {
      mockCurrentLocationService = MockCurrentLocationService();
      usecase = GetCurrentLocationUsecase(mockCurrentLocationService);
    });

    test('現在地取得サービスの結果をそのまま返す', () async {
      const expected = Coordinate(latitude: 35.681236, longitude: 139.767125);
      when(
        mockCurrentLocationService.getCurrentLocation(),
      ).thenAnswer((_) async => expected);

      final actual = await usecase.execute();

      expect(actual, expected);
      verify(mockCurrentLocationService.getCurrentLocation()).called(1);
    });

    test('サービスで例外が発生した場合はそのまま伝播する', () async {
      when(
        mockCurrentLocationService.getCurrentLocation(),
      ).thenThrow(TestException('現在地取得失敗'));

      expect(() => usecase.execute(), throwsA(isA<TestException>()));
    });
  });
}
