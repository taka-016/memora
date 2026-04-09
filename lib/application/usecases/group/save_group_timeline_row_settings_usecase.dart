import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_timeline_row_settings_dto.dart';
import 'package:memora/application/mappers/group/group_timeline_row_settings_mapper.dart';
import 'package:memora/domain/repositories/group/group_timeline_row_settings_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final saveGroupTimelineRowSettingsUsecaseProvider =
    Provider<SaveGroupTimelineRowSettingsUsecase>((ref) {
      return SaveGroupTimelineRowSettingsUsecase(
        ref.watch(groupTimelineRowSettingsRepositoryProvider),
      );
    });

class SaveGroupTimelineRowSettingsUsecase {
  const SaveGroupTimelineRowSettingsUsecase(this._repository);

  final GroupTimelineRowSettingsRepository _repository;

  Future<void> execute(GroupTimelineRowSettingsDto dto) async {
    await _repository.saveGroupTimelineRowSettings(
      GroupTimelineRowSettingsMapper.toEntity(dto),
    );
  }
}
