import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_timeline_row_settings_dto.dart';
import 'package:memora/application/queries/group/group_timeline_row_settings_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getGroupTimelineRowSettingsUsecaseProvider =
    Provider<GetGroupTimelineRowSettingsUsecase>((ref) {
      return GetGroupTimelineRowSettingsUsecase(
        ref.watch(groupTimelineRowSettingsQueryServiceProvider),
      );
    });

class GetGroupTimelineRowSettingsUsecase {
  const GetGroupTimelineRowSettingsUsecase(this._queryService);

  final GroupTimelineRowSettingsQueryService _queryService;

  Future<GroupTimelineRowSettingsDto> execute(GroupDto group) async {
    final savedSettings = await _queryService.getGroupTimelineRowSettings(
      group.id,
    );
    return (savedSettings ??
            GroupTimelineRowSettingsDto.defaultsForGroup(group))
        .mergeWithDefaultRows(group);
  }
}
