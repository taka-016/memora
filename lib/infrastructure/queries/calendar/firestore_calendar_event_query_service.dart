import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/queries/calendar/calendar_event_query_service.dart';
import 'package:memora/infrastructure/mappers/calendar/firestore_calendar_event_mapper.dart';

class FirestoreCalendarEventQueryService implements CalendarEventQueryService {
  FirestoreCalendarEventQueryService({
    required FirebaseFirestore firestore,
    required Future<void> Function(String) ensureMembership,
  }) : _firestore = firestore,
       _ensureMembership = ensureMembership;
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
    return snapshot.docs
        .map(FirestoreCalendarEventMapper.fromFirestore)
        .toList();
  }
}
