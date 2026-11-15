import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memora/composition_root/providers/background_task_providers.dart';

part 'startup_background_tasks_notifier.g.dart';

class StartupBackgroundTasksState {
  const StartupBackgroundTasksState({this.errors = const []});

  final List<String> errors;
}

@Riverpod(keepAlive: true)
class StartupBackgroundTasksNotifier extends _$StartupBackgroundTasksNotifier {
  @override
  StartupBackgroundTasksState build() => const StartupBackgroundTasksState();

  Future<void> start(Future<void> Function() waitBeforeReregistration) async {
    await ref
        .read(startupBackgroundRegistrationProvider)
        .start(
          waitBeforeReregistration: waitBeforeReregistration,
          onError: (message) {
            if (ref.mounted) {
              state = StartupBackgroundTasksState(
                errors: List.unmodifiable([...state.errors, message]),
              );
            }
          },
        );
  }

  void dismiss() => state = const StartupBackgroundTasksState();
}
