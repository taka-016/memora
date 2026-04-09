import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/timeline_row_settings_dto.dart';
import 'package:memora/application/queries/group/timeline_row_settings_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getTimelineRowSettingsUsecaseProvider =
    Provider<GetTimelineRowSettingsUsecase>((ref) {
      return GetTimelineRowSettingsUsecase(
        ref.watch(timelineRowSettingsQueryServiceProvider),
      );
    });

class GetTimelineRowSettingsUsecase {
  const GetTimelineRowSettingsUsecase(this._queryService);

  final TimelineRowSettingsQueryService _queryService;

  Future<TimelineRowSettingsDto> execute({
    required String groupId,
    required List<String> memberIds,
  }) async {
    final savedSettings = await _queryService.getTimelineRowSettingsByGroupId(
      groupId,
    );

    return savedSettings ??
        TimelineRowSettingsDto.defaults(groupId: groupId, memberIds: memberIds);
  }
}
