import 'package:memora/presentation/notifiers/startup/startup_common_data_notifier.dart';
import 'package:memora/composition_root/providers/startup_common_data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/usecases/calendar/change_calendar_recurrence_usecase.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifications_notifier.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';
import 'package:memora/core/app_logger.dart';

final calendarMutationCoordinatorProvider =
    Provider<CalendarMutationCoordinator>(CalendarMutationCoordinator.new);

class CalendarMutationCoordinator {
  CalendarMutationCoordinator(this.ref);
  final Ref ref;
  Future<String?> save(
    CalendarEventDto input, {
    CalendarEventDto? expected,
    CalendarEventDto? expectedSeries,
    CalendarChangeScope? scope,
  }) async {
    final result = await ref
        .read(calendarEventMutationUsecaseProvider)
        .save(
          input,
          expected: expected,
          expectedSeries: expectedSeries,
          scope: scope,
          currentMember: () => ref.read(currentMemberNotifierProvider).member,
        );
    await _refresh(result.affectedGroupIds, eventsChanged: true);
    return result.savedId;
  }

  Future<void> delete(
    CalendarEventDto expected, {
    CalendarEventDto? expectedSeries,
    CalendarChangeScope? scope,
  }) async {
    final result = await ref
        .read(calendarEventMutationUsecaseProvider)
        .delete(expected, expectedSeries: expectedSeries, scope: scope);
    await _refresh(result.affectedGroupIds, eventsChanged: true);
  }

  Future<void> labelsChanged(String groupId) async {
    if (ref.exists(startupCommonDataNotifierProvider) &&
        ref.read(startupCommonDataOwnerProvider) != null) {
      await ref
          .read(startupCommonDataNotifierProvider.notifier)
          .refreshLabels(groupId);
    }
    await _refresh({groupId});
  }

  Future<void> _refresh(Set<String> ids, {bool eventsChanged = false}) async {
    if (!ref.mounted) return;
    for (final id in ids) {
      final provider = calendarNotifierProvider(id);
      if (ref.exists(provider) && !ref.read(provider).isWatching) {
        await ref.read(provider.notifier).load();
      }
      if (!ref.mounted) return;
    }
    try {
      if (ref.exists(calendarNotificationsNotifierProvider)) {
        await ref
            .read(calendarNotificationsNotifierProvider.notifier)
            .refresh();
      }
      if (ref.mounted) {
        await ref.read(refreshSelectedCalendarWidgetCacheProvider)(
          force: !eventsChanged,
        );
      }
    } catch (error, stack) {
      logger.w('保存後の予定表示更新に失敗しました', error: error, stackTrace: stack);
    }
  }
}
