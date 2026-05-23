import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/dvc/delete_dvc_limited_point_usecase.dart';
import 'package:memora/domain/repositories/dvc/dvc_limited_point_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'delete_dvc_limited_point_usecase_test.mocks.dart';

@GenerateMocks([DvcLimitedPointRepository])
void main() {
  group('DeleteDvcLimitedPointUsecase', () {
    test('期間限定ポイントを削除できること', () async {
      final repository = MockDvcLimitedPointRepository();
      final usecase = DeleteDvcLimitedPointUsecase(repository);
      when(
        repository.deleteDvcLimitedPoint('limited-1'),
      ).thenAnswer((_) async {});

      await usecase.execute('limited-1');

      verify(repository.deleteDvcLimitedPoint('limited-1')).called(1);
    });
  });
}
