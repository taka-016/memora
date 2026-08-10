import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/usecases/dvc/delete_dvc_point_usage_usecase.dart';
import 'package:memora/application/usecases/dvc/save_dvc_point_usage_usecase.dart';
import 'package:memora/presentation/features/timeline/timeline_dvc_point_usages_refresh_provider.dart';

final dvcPointUsageMutationCoordinatorProvider =
    Provider<DvcPointUsageMutationCoordinator>((ref) {
      return DvcPointUsageMutationCoordinator._(
        saveDvcPointUsage: (pointUsage) {
          return ref.read(saveDvcPointUsageUsecaseProvider).execute(pointUsage);
        },
        deleteDvcPointUsage: (pointUsageId) {
          return ref
              .read(deleteDvcPointUsageUsecaseProvider)
              .execute(pointUsageId);
        },
        onDvcPointUsagesChanged: () {
          ref.invalidate(timelineDvcPointUsagesRefreshProvider);
        },
      );
    });

class DvcPointUsageMutationCoordinator {
  DvcPointUsageMutationCoordinator._({
    required this._saveDvcPointUsage,
    required this._deleteDvcPointUsage,
    required this._onDvcPointUsagesChanged,
  });

  final Future<void> Function(DvcPointUsageDto) _saveDvcPointUsage;
  final Future<void> Function(String) _deleteDvcPointUsage;
  final void Function() _onDvcPointUsagesChanged;

  Future<void> saveDvcPointUsage(DvcPointUsageDto pointUsage) async {
    await _saveDvcPointUsage(pointUsage);
    _onDvcPointUsagesChanged();
  }

  Future<void> deleteDvcPointUsage(String pointUsageId) async {
    await _deleteDvcPointUsage(pointUsageId);
    _onDvcPointUsagesChanged();
  }
}
