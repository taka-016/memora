import 'package:memora/presentation/notifiers/startup/startup_common_data_notifier.dart';
import 'package:memora/composition_root/providers/startup_common_data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
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
    if (expected?.originalStartDateTime != null) {
      if (expectedSeries == null ||
          expectedSeries.version != expected!.version ||
          expectedSeries.overridesFingerprint !=
              expected.overridesFingerprint ||
          expectedSeries.copyWith(
                startDateTime: expected.startDateTime,
                endDateTime: expected.endDateTime,
                originalStartDateTime: expected.originalStartDateTime,
                overrides: expected.overrides,
              ) !=
              expected) {
        throw const ApplicationValidationException(
          '予定が変更されています。再読み込みしてからやり直してください',
        );
      }
    }
    final moving = expected != null && expected.groupId != input.groupId;
    String? savedId = input.id;
    if (moving) {
      final member = ref.read(currentMemberNotifierProvider).member;
      if (member == null) {
        throw const ApplicationValidationException('利用者を確認できません。再読み込みしてください');
      }
      await ref
          .read(moveCalendarEventUsecaseProvider)
          .execute(expectedSeries ?? expected, input, member);
    } else if (expected?.originalStartDateTime != null) {
      if (expectedSeries == null || scope == null) {
        throw const ApplicationValidationException(
          '変更する系列を確認できません。再読み込みしてください',
        );
      }
      savedId = await ref
          .read(changeCalendarRecurrenceUsecaseProvider)
          .execute(
            expectedSeries,
            expected!.originalStartDateTime!,
            scope,
            changes: input,
          );
    } else if (input.id.isEmpty) {
      savedId = await ref
          .read(createCalendarEventUsecaseProvider)
          .execute(input);
    } else {
      await ref.read(updateCalendarEventUsecaseProvider).execute(input);
    }
    await _refresh({
      if (expected != null) expected.groupId,
      input.groupId,
    }, eventsChanged: true);
    return savedId;
  }

  Future<void> delete(
    CalendarEventDto expected, {
    CalendarEventDto? expectedSeries,
    CalendarChangeScope? scope,
  }) async {
    if (expected.originalStartDateTime != null) {
      if (expectedSeries != null &&
          (expectedSeries.version != expected.version ||
              expectedSeries.overridesFingerprint !=
                  expected.overridesFingerprint ||
              expectedSeries.copyWith(
                    startDateTime: expected.startDateTime,
                    endDateTime: expected.endDateTime,
                    originalStartDateTime: expected.originalStartDateTime,
                    overrides: expected.overrides,
                  ) !=
                  expected)) {
        throw const ApplicationValidationException(
          '予定が変更されています。再読み込みしてからやり直してください',
        );
      }
      if (expectedSeries == null || scope == null) {
        throw const ApplicationValidationException(
          '変更する系列を確認できません。再読み込みしてください',
        );
      }
      await ref
          .read(changeCalendarRecurrenceUsecaseProvider)
          .execute(expectedSeries, expected.originalStartDateTime!, scope);
    } else {
      await ref
          .read(deleteCalendarEventUsecaseProvider)
          .execute(expected.id, expectedVersion: expected.version);
    }
    await _refresh({expected.groupId}, eventsChanged: true);
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
