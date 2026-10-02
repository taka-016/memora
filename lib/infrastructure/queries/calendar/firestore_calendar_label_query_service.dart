import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/queries/calendar/calendar_label_query_service.dart';
import 'package:memora/infrastructure/mappers/calendar/firestore_calendar_label_mapper.dart';

class FirestoreCalendarLabelQueryService implements CalendarLabelQueryService {
  FirestoreCalendarLabelQueryService({
    required this._firestore,
    required this._ensureMembership,
  });
  final FirebaseFirestore _firestore;
  final Future<void> Function(String) _ensureMembership;
  @override
  Future<List<CalendarLabelDto>> getCalendarLabelsByGroupId(
    String groupId,
  ) async {
    await _ensureMembership(groupId);
    final snapshot = await _firestore
        .collection('calendar_labels')
        .where('groupId', isEqualTo: groupId)
        .get();
    return snapshot.docs
        .map(FirestoreCalendarLabelMapper.fromFirestore)
        .toList();
  }
}
