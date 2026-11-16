import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/queries/calendar/calendar_label_query_service.dart';
import 'package:memora/infrastructure/mappers/calendar/firestore_calendar_label_mapper.dart';

class FirestoreCalendarLabelQueryService implements CalendarLabelQueryService {
  FirestoreCalendarLabelQueryService({
    required FirebaseFirestore firestore,
    this.options = const GetOptions(),
  }) : firestore = firestore;
  final FirebaseFirestore firestore;
  final GetOptions options;
  @override
  Future<List<CalendarLabelDto>> getCalendarLabelsByGroupId(
    String groupId,
  ) async {
    final snapshot = await firestore
        .collection('calendar_labels')
        .where('groupId', isEqualTo: groupId)
        .get(options);
    return snapshot.docs
        .map(FirestoreCalendarLabelMapper.fromFirestore)
        .toList()
      ..sort(compareCalendarLabels);
  }
}
