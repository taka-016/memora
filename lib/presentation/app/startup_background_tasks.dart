import 'package:memora/presentation/notifiers/startup/startup_common_data_notifier.dart';
import 'package:memora/composition_root/providers/startup_common_data_providers.dart';
import 'package:memora/presentation/notifiers/timeline/group_timeline_group_selection_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_group_settings_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_preferences_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notification_preferences_notifier.dart';
import 'package:memora/presentation/notifiers/setting/theme_settings_notifier.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/presentation/notifiers/startup/startup_background_tasks_notifier.dart';

class StartupBackgroundTasks extends ConsumerStatefulWidget {
  const StartupBackgroundTasks({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<StartupBackgroundTasks> createState() =>
      _StartupBackgroundTasksState();
}

class _StartupBackgroundTasksState
    extends ConsumerState<StartupBackgroundTasks> {
  final _firstFrame = Completer<void>();
  bool _frameScheduled = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      ref.read(startupBackgroundTasksNotifierProvider.notifier).start(() async {
        await _firstFrame.future;
        await Future<void>.delayed(const Duration(seconds: 3));
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(startupCommonDataNotifierProvider, (_, next) {
      final groups = next.data.groups;
      final member = ref.read(startupCommonDataMemberIdProvider);
      if (groups != null && member != null) {
        ref
            .read(groupTimelineGroupSelectionNotifierProvider.notifier)
            .setLoadedGroups(memberId: member, groups: groups);
      }
    });
    ref.watch(calendarGroupSettingsNotifierProvider);
    ref.watch(calendarPreferencesNotifierProvider);
    ref.watch(calendarNotificationPreferencesNotifierProvider);
    if (!ref.watch(themeSettingsNotifierProvider).isLoading &&
        !_frameScheduled) {
      _frameScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_firstFrame.isCompleted) _firstFrame.complete();
      });
    }
    return widget.child;
  }
}

class StartupBackgroundRegistrationNotice extends ConsumerWidget {
  const StartupBackgroundRegistrationNotice({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errors = ref.watch(startupBackgroundTasksNotifierProvider).errors;
    return Column(
      children: [
        if (errors.isNotEmpty)
          SafeArea(
            bottom: false,
            child: MaterialBanner(
              content: Text(errors.join('\n')),
              actions: [
                TextButton(
                  onPressed: () => ref
                      .read(startupBackgroundTasksNotifierProvider.notifier)
                      .dismiss(),
                  child: const Text('閉じる'),
                ),
              ],
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}
