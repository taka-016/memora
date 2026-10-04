import 'package:memora/application/usecases/calendar/change_calendar_recurrence_usecase.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_expander.dart';
import 'package:memora/infrastructure/services/iana_calendar_time_zone.dart';
import 'package:memora/application/usecases/calendar/reorder_calendar_labels_usecase.dart';
import 'package:memora/application/services/calendar_default_duration_storage.dart';
import 'package:memora/infrastructure/services/shared_preferences_calendar_default_duration_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/calendar/get_calendar_events_usecase.dart';
import 'package:memora/application/usecases/calendar/get_calendar_labels_usecase.dart';
import 'package:memora/application/usecases/calendar/create_calendar_event_usecase.dart';
import 'package:memora/application/usecases/calendar/update_calendar_event_usecase.dart';
import 'package:memora/application/usecases/calendar/delete_calendar_event_usecase.dart';
import 'package:memora/application/usecases/calendar/save_calendar_label_usecase.dart';
import 'package:memora/application/usecases/calendar/delete_calendar_label_usecase.dart';

final getCalendarEventsUsecaseProvider = Provider<GetCalendarEventsUsecase>(
  (ref) =>
      GetCalendarEventsUsecase(ref.watch(calendarEventQueryServiceProvider)),
);

final getCalendarLabelsUsecaseProvider = Provider<GetCalendarLabelsUsecase>(
  (ref) =>
      GetCalendarLabelsUsecase(ref.watch(calendarLabelQueryServiceProvider)),
);

final createCalendarEventUsecaseProvider = Provider<CreateCalendarEventUsecase>(
  (ref) =>
      CreateCalendarEventUsecase(ref.watch(calendarEventRepositoryProvider)),
);

final updateCalendarEventUsecaseProvider = Provider<UpdateCalendarEventUsecase>(
  (ref) =>
      UpdateCalendarEventUsecase(ref.watch(calendarEventRepositoryProvider)),
);

final deleteCalendarEventUsecaseProvider = Provider<DeleteCalendarEventUsecase>(
  (ref) =>
      DeleteCalendarEventUsecase(ref.watch(calendarEventRepositoryProvider)),
);

final saveCalendarLabelUsecaseProvider = Provider<SaveCalendarLabelUsecase>(
  (ref) => SaveCalendarLabelUsecase(ref.watch(calendarLabelRepositoryProvider)),
);

final deleteCalendarLabelUsecaseProvider = Provider<DeleteCalendarLabelUsecase>(
  (ref) =>
      DeleteCalendarLabelUsecase(ref.watch(calendarLabelRepositoryProvider)),
);

final calendarDefaultDurationStorageProvider =
    Provider<CalendarDefaultDurationStorage>(
      (ref) => const SharedPreferencesCalendarDefaultDurationStorage(),
    );

final reorderCalendarLabelsUsecaseProvider =
    Provider<ReorderCalendarLabelsUsecase>(
      (ref) => ReorderCalendarLabelsUsecase(
        ref.watch(calendarLabelRepositoryProvider),
      ),
    );

final calendarRecurrenceExpanderProvider = Provider<CalendarRecurrenceExpander>(
  (ref) => CalendarRecurrenceExpander(IanaCalendarTimeZone()),
);

final changeCalendarRecurrenceUsecaseProvider =
    Provider<ChangeCalendarRecurrenceUsecase>(
      (ref) => ChangeCalendarRecurrenceUsecase(
        ref.watch(calendarEventRepositoryProvider),
        ref.watch(calendarRecurrenceExpanderProvider),
      ),
    );
