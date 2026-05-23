import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/usecases/dvc/save_dvc_point_usage_usecase.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_usage_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'save_dvc_point_usage_usecase_test.mocks.dart';

@GenerateMocks([DvcPointUsageRepository])
void main() {
  group('SaveDvcPointUsageUsecase', () {
    test('利用ポイントを保存できること', () async {
      final repository = MockDvcPointUsageRepository();
      final usecase = SaveDvcPointUsageUsecase(repository);
      final usage = DvcPointUsageDto(
        id: '',
        groupId: 'group-1',
        usageYearMonth: DateTime(2026, 1),
        usedPoint: 25,
        memo: 'レストラン',
      );
      when(repository.saveDvcPointUsage(any)).thenAnswer((_) async {});

      await usecase.execute(usage);

      final verification = verify(repository.saveDvcPointUsage(captureAny))
        ..called(1);
      final savedUsage = verification.captured.single as DvcPointUsage;
      expect(savedUsage.groupId, equals('group-1'));
      expect(savedUsage.usedPoint, equals(25));
      expect(savedUsage.memo, equals('レストラン'));
    });
  });
}
