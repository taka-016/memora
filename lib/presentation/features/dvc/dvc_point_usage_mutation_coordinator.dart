import 'package:memora/composition_root/providers/dvc_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/presentation/features/timeline/timeline_dvc_point_usages_provider.dart';

final dvcPointUsageMutationCoordinatorProvider =
    Provider<DvcPointUsageMutationCoordinator>((ref) {
      return DvcPointUsageMutationCoordinator._(
        saveDvcPointUsage: (pointUsage, {expectedContractVersion}) {
          return ref
              .read(saveDvcPointUsageUsecaseProvider)
              .execute(
                pointUsage,
                expectedContractVersion: expectedContractVersion,
              );
        },
        deleteDvcPointUsage: (pointUsageId, {expectedContractVersion}) {
          return ref
              .read(deleteDvcPointUsageUsecaseProvider)
              .execute(
                pointUsageId,
                expectedContractVersion: expectedContractVersion,
              );
        },
        onDvcPointUsagesChanged: () {
          ref.invalidate(timelineDvcPointUsagesByYearProvider);
        },
      );
    });

class DvcPointUsageMutationCoordinator {
  DvcPointUsageMutationCoordinator._({
    required this._saveDvcPointUsage,
    required this._deleteDvcPointUsage,
    required this._onDvcPointUsagesChanged,
  });

  final Future<void> Function(DvcPointUsageDto, {int? expectedContractVersion})
  _saveDvcPointUsage;
  final Future<void> Function(String, {int? expectedContractVersion})
  _deleteDvcPointUsage;
  final void Function() _onDvcPointUsagesChanged;

  Future<void> saveDvcPointUsage(
    DvcPointUsageDto pointUsage, {
    int? expectedContractVersion,
  }) async {
    await _saveDvcPointUsage(
      pointUsage,
      expectedContractVersion: expectedContractVersion,
    );
    _onDvcPointUsagesChanged();
  }

  Future<void> deleteDvcPointUsage(
    String pointUsageId, {
    int? expectedContractVersion,
  }) async {
    await _deleteDvcPointUsage(
      pointUsageId,
      expectedContractVersion: expectedContractVersion,
    );
    _onDvcPointUsagesChanged();
  }
}
