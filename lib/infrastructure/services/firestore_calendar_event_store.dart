import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/domain/entities/calendar/calendar_event.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/infrastructure/mappers/calendar/firestore_calendar_event_mapper.dart';
import 'package:memora/infrastructure/mappers/calendar/firestore_calendar_event_override_mapper.dart';
import 'package:memora/infrastructure/mappers/firestore_write_metadata.dart';

class FirestoreCalendarEventStore {
  FirestoreCalendarEventStore(this.firestore);
  final FirebaseFirestore firestore;

  List<String> overrideIds(Map<String, dynamic> data) =>
      (data['overrideIds'] as List? ?? []).cast<String>();

  Future<CalendarEventDto> read(
    DocumentSnapshot<Map<String, dynamic>> event, {
    Transaction? transaction,
  }) async {
    final data = event.data()!;
    final overrides = <CalendarEventOverride>[];
    for (final id in overrideIds(data)) {
      final ref = firestore.collection('calendar_event_overrides').doc(id);
      final doc = transaction == null
          ? await ref.get()
          : await transaction.get(ref);
      final row = doc.data();
      if (row == null ||
          row['eventId'] != event.id ||
          row['groupId'] != data['groupId']) {
        throw ValidationException('個別回の保存内容が不正です');
      }
      overrides.add(
        FirestoreCalendarEventOverrideMapper.fromFirestore(
          row,
          parentAllDay: data['isAllDay'] as bool,
        ),
      );
    }
    return FirestoreCalendarEventMapper.fromFirestore(
      event,
      overrides: overrides,
    );
  }

  Map<String, dynamic> data(
    CalendarEvent event,
    String id, {
    required bool create,
  }) => {
    ...create
        ? FirestoreCalendarEventMapper.toCreateFirestore(event)
        : FirestoreCalendarEventMapper.toUpdateFirestore(event),
    'overrideIds': event.overrides
        .map(
          (value) => FirestoreCalendarEventOverrideMapper.documentId(
            id,
            value,
            event.isAllDay,
          ),
        )
        .toList(),
  };

  void writeOverrides(
    Transaction transaction,
    CalendarEvent? event,
    String eventId,
    List<String> previousIds,
  ) {
    final collection = firestore.collection('calendar_event_overrides');
    final values = {
      for (final value in event?.overrides ?? <CalendarEventOverride>[])
        FirestoreCalendarEventOverrideMapper.documentId(
          eventId,
          value,
          event!.isAllDay,
        ): value,
    };
    for (final id in previousIds) {
      if (!values.containsKey(id)) transaction.delete(collection.doc(id));
    }
    for (final entry in values.entries) {
      final data = FirestoreCalendarEventOverrideMapper.toFirestore(
        entry.value,
        eventId: eventId,
        groupId: event!.groupId,
        parentAllDay: event.isAllDay,
      );
      final ref = collection.doc(entry.key);
      if (previousIds.contains(entry.key)) {
        transaction.update(ref, {
          ...data,
          ...FirestoreWriteMetadata.forUpdate(),
        });
      } else {
        transaction.set(ref, {...data, ...FirestoreWriteMetadata.forCreate()});
      }
    }
  }
}
