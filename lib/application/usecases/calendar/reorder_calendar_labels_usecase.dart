import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/calendar/calendar_label_repository.dart';

class ReorderCalendarLabelsUsecase {
  ReorderCalendarLabelsUsecase(this._repository);
  final CalendarLabelRepository _repository;
  Future<void> execute(String groupId, List<String> labelIds) async {
    if (groupId.trim().isEmpty ||
        labelIds.any((id) => id.trim().isEmpty) ||
        labelIds.toSet().length != labelIds.length) {
      throw const ApplicationValidationException('同じグループの色ラベルを重複なく指定してください');
    }
    try {
      await _repository.reorderCalendarLabels(
        groupId,
        List.unmodifiable(labelIds),
      );
    } on ValidationException catch (error, stack) {
      Error.throwWithStackTrace(
        ApplicationValidationException(error.message),
        stack,
      );
    }
  }
}
