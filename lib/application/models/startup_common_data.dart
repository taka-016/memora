import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';

class StartupCommonData {
  StartupCommonData({
    List<GroupDto>? groups,
    Map<String, List<CalendarLabelDto>> labels = const {},
  }) : groups = groups == null ? null : List.unmodifiable(groups),
       labels = Map.unmodifiable({
         for (final entry in labels.entries)
           entry.key: List<CalendarLabelDto>.unmodifiable(entry.value),
       });

  final List<GroupDto>? groups;
  final Map<String, List<CalendarLabelDto>> labels;
}
