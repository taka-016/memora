import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/application/mappers/calendar/calendar_label_mapper.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/calendar/calendar_label_repository.dart';

class SaveCalendarLabelUsecase {
  SaveCalendarLabelUsecase(this._repository);

  final CalendarLabelRepository _repository;

  Future<CalendarLabelDto> execute(CalendarLabelDto dto) async {
    try {
      final entity = CalendarLabelMapper.toEntity(dto);
      final savedId = await _repository.saveCalendarLabel(entity);
      return dto.copyWith(id: savedId);
    } on ValidationException catch (e, stack) {
      Error.throwWithStackTrace(
        ApplicationValidationException(e.message),
        stack,
      );
    }
  }
}
