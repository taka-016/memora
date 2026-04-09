import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/timeline_row_settings_dto.dart';
import 'package:memora/application/mappers/group/timeline_row_settings_mapper.dart';
import 'package:memora/domain/repositories/group/timeline_row_settings_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final createTimelineRowSettingsUsecaseProvider =
    Provider<CreateTimelineRowSettingsUsecase>((ref) {
      return CreateTimelineRowSettingsUsecase(
        ref.watch(timelineRowSettingsRepositoryProvider),
      );
    });

class CreateTimelineRowSettingsUsecase {
  const CreateTimelineRowSettingsUsecase(this._repository);

  final TimelineRowSettingsRepository _repository;

  Future<void> execute(TimelineRowSettingsDto settings) async {
    await _repository.createTimelineRowSettings(
      TimelineRowSettingsMapper.toEntity(settings),
    );
  }
}
