import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/dvc/delete_dvc_point_usage_usecase.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_usage_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'delete_dvc_point_usage_usecase_test.mocks.dart';

@GenerateMocks([DvcPointUsageRepository])
void main() {
  group('DeleteDvcPointUsageUsecase', () {
    test('利用ポイントを削除できること', () async {
      final repository = MockDvcPointUsageRepository();
      final usecase = DeleteDvcPointUsageUsecase(repository);
      when(repository.deleteDvcPointUsage('usage-1')).thenAnswer((_) async {});

      await usecase.execute('usage-1');

      verify(repository.deleteDvcPointUsage('usage-1')).called(1);
    });
  });
}
