import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/queries/calendar/calendar_label_watch_query_service.dart';
import 'package:memora/infrastructure/mappers/calendar/firestore_calendar_label_mapper.dart';
import 'package:memora/infrastructure/services/shared_calendar_cache.dart';

class FirestoreCalendarLabelWatchQueryService
    implements CalendarLabelWatchQueryService {
  FirestoreCalendarLabelWatchQueryService({
    required this.firestore,
    this.sharedCache,
    this.currentOwnerId,
  });
  final FirebaseFirestore firestore;
  final SharedCalendarCache? sharedCache;
  final String? Function()? currentOwnerId;

  @override
  Stream<List<CalendarLabelDto>> watchCalendarLabelsByGroupId(String groupId) {
    final query = firestore
        .collection('calendar_labels')
        .where('groupId', isEqualTo: groupId);
    final cache = sharedCache;
    final ownerId = currentOwnerId?.call();
    if (cache == null || ownerId == null) return query.snapshots().map(_labels);
    return _watchCached(query, cache, ownerId, groupId);
  }

  Stream<List<CalendarLabelDto>> _watchCached(
    Query<Map<String, dynamic>> query,
    SharedCalendarCache cache,
    String ownerId,
    String groupId,
  ) async* {
    final cached = await cache.loadLabels(ownerId, groupId);
    if (currentOwnerId?.call() != ownerId) return;
    var waitingForServer = cached != null;
    if (cached != null) yield cached;

    yield* query
        .snapshots(includeMetadataChanges: true)
        .asyncMap((snapshot) async {
          if (currentOwnerId?.call() != ownerId) return null;
          final confirmed =
              !snapshot.metadata.isFromCache &&
              !snapshot.metadata.hasPendingWrites;
          if (!confirmed && waitingForServer) return null;
          final labels = _labels(snapshot);
          if (confirmed) {
            waitingForServer = false;
            await cache.saveLabels(
              ownerId,
              groupId,
              labels,
              observedAt: DateTime.now().microsecondsSinceEpoch,
            );
          }
          return currentOwnerId?.call() == ownerId ? labels : null;
        })
        .where((labels) => labels != null)
        .cast<List<CalendarLabelDto>>();
  }

  List<CalendarLabelDto> _labels(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) =>
      snapshot.docs.map(FirestoreCalendarLabelMapper.fromFirestore).toList()
        ..sort(compareCalendarLabels);
}
