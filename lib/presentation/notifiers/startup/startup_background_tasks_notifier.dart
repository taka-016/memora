import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memora/composition_root/providers/background_task_providers.dart';

part 'startup_background_tasks_notifier.g.dart';

@Riverpod(keepAlive: true)
class StartupBackgroundTasksNotifier extends _$StartupBackgroundTasksNotifier {
  @override
  List<String> build() => const [];

  Future<void> start(Future<void> Function() waitBeforeReregistration) async {
    await ref
        .read(startupBackgroundRegistrationProvider)
        .start(
          waitBeforeReregistration: waitBeforeReregistration,
          onError: (message) {
            if (ref.mounted) state = [...state, message];
          },
        );
  }

  void dismiss() => state = const [];
}
