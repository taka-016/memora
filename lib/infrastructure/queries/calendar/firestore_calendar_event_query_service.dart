import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/mappers/calendar/calendar_event_mapper.dart';
import 'package:memora/application/queries/calendar/calendar_event_query_service.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/infrastructure/mappers/calendar/firestore_calendar_event_mapper.dart';
import 'package:memora/infrastructure/services/validate_calendar_recurrence.dart';

class FirestoreCalendarEventQueryService implements CalendarEventQueryService {
  FirestoreCalendarEventQueryService({
    required this._firestore,
    required this._ensureMembership,
  });
  final FirebaseFirestore _firestore;
  final Future<void> Function(String) _ensureMembership;
  @override
  Future<List<CalendarEventDto>> getCalendarEventsByGroupId(
    String groupId,
  ) async {
    await _ensureMembership(groupId);
    final snapshot = await _firestore
        .collection('calendar_events')
        .where('groupId', isEqualTo: groupId)
        .get();
    final events = <CalendarEventDto>[];
    for (final doc in snapshot.docs) {
      try {
        final event = FirestoreCalendarEventMapper.fromFirestore(doc);
        validateCalendarRecurrence(CalendarEventMapper.toEntity(event));
        events.add(event);
      } on TypeError {
        continue;
      } on ValidationException {
        continue;
      }
    }
    return events;
  }
}
