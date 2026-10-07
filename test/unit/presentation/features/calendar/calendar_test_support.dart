import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/infrastructure/time/fixed_app_clock.dart';
import 'package:memora/presentation/features/calendar/calendar_screen.dart';

import '../../notifiers/calendar/calendar_notifier_test.mocks.dart';

const calendarTestDay2 = Key('calendar_day_2026_10_2');
const calendarTestFamily = CalendarLabelDto(
  id: 'family',
  groupId: 'g1',
  name: '家族全員',
  color: '#123ABC',
);

CalendarEventDto calendarTestEvent(String id, String title) => CalendarEventDto(
  id: id,
  groupId: 'g1',
  labelId: 'family',
  title: title,
  startDateTime: DateTime(2026, 10, 2, 9),
  endDateTime: DateTime(2026, 10, 2, 10),
  isAllDay: false,
);

class CalendarTestHarness {
  final events = MockGetCalendarEventsUsecase();
  final labels = MockGetCalendarLabelsUsecase();
  final create = MockCreateCalendarEventUsecase();
  final update = MockUpdateCalendarEventUsecase();
  final delete = MockDeleteCalendarEventUsecase();
  final saveLabel = MockSaveCalendarLabelUsecase();
  final reorder = MockReorderCalendarLabelsUsecase();
  final changeRecurrence = MockChangeCalendarRecurrenceUsecase();
  final savedEvents = <CalendarEventDto>[];
  final savedLabels = <CalendarLabelDto>[calendarTestFamily];

  Future<void> pump(
    WidgetTester tester, {
    double textScale = 1,
    DateTime? now,
  }) async {
    when(events.execute('g1')).thenAnswer((_) async => List.of(savedEvents));
    when(labels.execute('g1')).thenAnswer((_) async => List.of(savedLabels));
    when(reorder.execute('g1', any)).thenAnswer((call) async {
      final ids = call.positionalArguments[1] as List<String>;
      final ordered = [
        for (var index = 0; index < ids.length; index++)
          savedLabels
              .firstWhere((label) => label.id == ids[index])
              .copyWith(sortOrder: index),
      ];
      savedLabels
        ..clear()
        ..addAll(ordered);
    });
    when(create.execute(any)).thenAnswer((call) async {
      savedEvents.add(
        (call.positionalArguments.single as CalendarEventDto).copyWith(
          id: 'new',
        ),
      );
      return 'new';
    });
    when(update.execute(any)).thenAnswer((call) async {
      final event = call.positionalArguments.single as CalendarEventDto;
      savedEvents[savedEvents.indexWhere((item) => item.id == event.id)] =
          event;
    });
    when(delete.execute(any)).thenAnswer((call) async {
      savedEvents.removeWhere(
        (event) => event.id == call.positionalArguments.single,
      );
    });
    when(saveLabel.execute(any)).thenAnswer((call) async {
      final input = call.positionalArguments.single as CalendarLabelDto;
      final label = input.id.isEmpty ? input.copyWith(id: 'new-label') : input;
      final index = savedLabels.indexWhere((item) => item.id == label.id);
      if (index < 0) {
        savedLabels.add(label);
      } else {
        savedLabels[index] = label;
      }
      return label;
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          changeCalendarRecurrenceUsecaseProvider.overrideWithValue(
            changeRecurrence,
          ),
          appClockProvider.overrideWithValue(
            FixedAppClock(now ?? DateTime(2026, 10, 1)),
          ),
          getCalendarEventsUsecaseProvider.overrideWithValue(events),
          getCalendarLabelsUsecaseProvider.overrideWithValue(labels),
          createCalendarEventUsecaseProvider.overrideWithValue(create),
          updateCalendarEventUsecaseProvider.overrideWithValue(update),
          deleteCalendarEventUsecaseProvider.overrideWithValue(delete),
          saveCalendarLabelUsecaseProvider.overrideWithValue(saveLabel),
          reorderCalendarLabelsUsecaseProvider.overrideWithValue(reorder),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: CalendarScreen(groupId: 'g1', groupName: '家族', onBack: () {}),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }
}
