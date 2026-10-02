import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/application/mappers/calendar/calendar_event_mapper.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/calendar/calendar_event_repository.dart';

class UpdateCalendarEventUsecase {
  UpdateCalendarEventUsecase(this._repository);

  final CalendarEventRepository _repository;

  Future<void> execute(CalendarEventDto dto) async {
    if (dto.id.trim().isEmpty) {
      throw const ApplicationValidationException('更新する予定のIDは必須です');
    }
    try {
      final entity = CalendarEventMapper.toEntity(dto);
      await _repository.updateCalendarEvent(entity);
    } on ValidationException catch (e, stack) {
      Error.throwWithStackTrace(
        ApplicationValidationException(e.message),
        stack,
      );
    }
  }
}
