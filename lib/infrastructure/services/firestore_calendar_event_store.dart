import 'package:memora/application/models/calendar_event_period.dart';
import 'package:flutter/foundation.dart';
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
    CalendarEventPeriod? period,
  }) async {
    final data = event.data()!;
    final overrides = <CalendarEventOverride>[];
    if (transaction == null && data['recurrenceRule'] != null) {
      var query = firestore
          .collection('calendar_event_overrides')
          .where('eventId', isEqualTo: event.id)
          .where('groupId', isEqualTo: data['groupId']);
      if (period != null) {
        query = query
            .where(
              'originalEndDateTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(period.queryFrom),
            )
            .where(
              'originalStartDateTime',
              isLessThan: Timestamp.fromDate(period.queryTo),
            )
            .orderBy('originalEndDateTime')
            .orderBy('originalStartDateTime');
      }
      final snapshot = await query.get();
      overrides.addAll(
        snapshot.docs.map(
          (doc) => FirestoreCalendarEventOverrideMapper.fromFirestore(
            doc.data(),
            parentAllDay: data['isAllDay'] as bool,
          ),
        ),
      );
    } else if (transaction != null) {
      for (final id in overrideIds(data)) {
        final doc = await transaction.get(
          firestore.collection('calendar_event_overrides').doc(id),
        );
        final row = doc.data();
        if (row == null ||
            row['eventId'] != event.id ||
            row['groupId'] != data['groupId']) {
          throw ValidationException('取消情報の保存内容が不正です');
        }
        overrides.add(
          FirestoreCalendarEventOverrideMapper.fromFirestore(
            row,
            parentAllDay: data['isAllDay'] as bool,
          ),
        );
      }
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
    List<String> previousIds, {
    CalendarEvent? previousEvent,
  }) {
    final collection = firestore.collection('calendar_event_overrides');
    final previousIdSet = previousIds.toSet();
    final values = {
      for (final value in event?.overrides ?? <CalendarEventOverride>[])
        FirestoreCalendarEventOverrideMapper.documentId(
          eventId,
          value,
          event!.isAllDay,
        ): value,
    };
    final previousValues = {
      for (final value in previousEvent?.overrides ?? <CalendarEventOverride>[])
        FirestoreCalendarEventOverrideMapper.documentId(
          eventId,
          value,
          previousEvent!.isAllDay,
        ): FirestoreCalendarEventOverrideMapper.toFirestore(
          value,
          eventId: eventId,
          groupId: previousEvent.groupId,
          parentAllDay: previousEvent.isAllDay,
          parentDuration: previousEvent.duration,
        ),
    };
    for (final id in previousIdSet) {
      if (!values.containsKey(id)) transaction.delete(collection.doc(id));
    }
    for (final entry in values.entries) {
      final data = FirestoreCalendarEventOverrideMapper.toFirestore(
        entry.value,
        eventId: eventId,
        groupId: event!.groupId,
        parentAllDay: event.isAllDay,
        parentDuration: event.duration,
      );
      final ref = collection.doc(entry.key);
      if (previousIdSet.contains(entry.key)) {
        final previous = previousValues[entry.key];
        if (previous != null &&
            data.entries.every(
              (entry) => entry.value is List
                  ? listEquals(
                      previous[entry.key] as List?,
                      entry.value as List,
                    )
                  : previous[entry.key] == entry.value,
            )) {
          continue;
        }
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
