import 'package:flutter/material.dart';
import 'package:memora/presentation/features/calendar/calendar_screen.dart';

class CalendarNavigationView extends StatelessWidget {
  const CalendarNavigationView({super.key, this.groupId, this.initialDate, this.createEvent = false, this.initialRequest = 0, this.initialEventId, this.initialOccurrence});
  final String? groupId;
  final DateTime? initialDate;
  final bool createEvent;
  final int initialRequest;
  final String? initialEventId;
  final DateTime? initialOccurrence;
  @override
  Widget build(BuildContext context) => CalendarScreen(groupId: groupId, initialDate: initialDate, createEvent: createEvent, initialRequest: initialRequest, initialEventId: initialEventId, initialOccurrence: initialOccurrence);
}
