import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/queries/calendar/calendar_label_watch_query_service.dart';
import 'package:memora/infrastructure/mappers/calendar/firestore_calendar_label_mapper.dart';

class FirestoreCalendarLabelWatchQueryService
    implements CalendarLabelWatchQueryService {
  FirestoreCalendarLabelWatchQueryService({required this.firestore});
  final FirebaseFirestore firestore;

  @override
  Stream<List<CalendarLabelDto>> watchCalendarLabelsByGroupId(String groupId) =>
      firestore
          .collection('calendar_labels')
          .where('groupId', isEqualTo: groupId)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map(FirestoreCalendarLabelMapper.fromFirestore)
                    .toList()
                  ..sort(compareCalendarLabels),
          );
}
