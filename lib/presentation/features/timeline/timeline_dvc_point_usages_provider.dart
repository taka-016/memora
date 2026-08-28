import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/usecases/dvc/get_dvc_point_usages_usecase.dart';
import 'package:memora/presentation/features/timeline/timeline_rows_refresh_provider.dart';

final timelineDvcPointUsagesByYearProvider = FutureProvider.autoDispose
    .family<Map<int, List<DvcPointUsageDto>>, String>((ref, groupId) async {
      ref.watch(timelineRowsRefreshProvider);
      final usages = await ref
          .watch(getDvcPointUsagesUsecaseProvider)
          .execute(groupId);
      return _groupDvcPointUsagesByYear(usages);
    }, retry: (_, _) => null);

Map<int, List<DvcPointUsageDto>> _groupDvcPointUsagesByYear(
  List<DvcPointUsageDto> usages,
) {
  final grouped = <int, List<DvcPointUsageDto>>{};
  for (final usage in usages) {
    grouped.putIfAbsent(usage.usageYearMonth.year, () => []).add(usage);
  }

  for (final entry in grouped.entries) {
    entry.value.sort((a, b) {
      final comparedMonth = a.usageYearMonth.compareTo(b.usageYearMonth);
      if (comparedMonth != 0) {
        return comparedMonth;
      }
      return a.id.compareTo(b.id);
    });
  }

  return grouped;
}
