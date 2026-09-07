import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_copy_notifier.g.dart';

@Riverpod(keepAlive: true, name: 'copiedTaskTripIdProvider')
class TaskCopyNotifier extends _$TaskCopyNotifier {
  @override
  String? build() => null;

  void setTripId(String? tripId) {
    state = tripId;
  }
}
