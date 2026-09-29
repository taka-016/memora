import 'package:equatable/equatable.dart';
import 'package:memora/application/models/offline_backup_snapshot.dart';
import 'package:memora/composition_root/providers/offline_backup_providers.dart';
import 'package:memora/presentation/features/timeline/timeline_display_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'offline_backup_notifier.g.dart';

class OfflineBackupState extends Equatable {
  const OfflineBackupState({
    this.isWorking = false,
    this.isRestoring = false,
    this.preparedRestore,
  });

  final bool isWorking;
  final bool isRestoring;
  final OfflineBackupSnapshot? preparedRestore;

  @override
  List<Object?> get props => [isWorking, isRestoring, preparedRestore];
}

@riverpod
class OfflineBackupNotifier extends _$OfflineBackupNotifier {
  @override
  OfflineBackupState build() => const OfflineBackupState();

  Future<bool> create(String password) async {
    if (state.isWorking) return false;
    final keepAliveLink = ref.keepAlive();
    state = OfflineBackupState(
      isWorking: true,
      preparedRestore: state.preparedRestore,
    );
    try {
      return await ref
          .read(createOfflineBackupUsecaseProvider)
          .execute(password);
    } finally {
      if (ref.mounted) {
        state = OfflineBackupState(preparedRestore: state.preparedRestore);
      }
      keepAliveLink.close();
    }
  }

  Future<bool> prepareRestore(String password) async {
    if (state.isWorking) return false;
    final keepAliveLink = ref.keepAlive();
    state = OfflineBackupState(
      isWorking: true,
      preparedRestore: state.preparedRestore,
    );
    try {
      final snapshot = await ref
          .read(prepareOfflineRestoreUsecaseProvider)
          .execute(password);
      if (!ref.mounted) return false;
      state = OfflineBackupState(preparedRestore: snapshot);
      return snapshot != null;
    } catch (_) {
      if (ref.mounted) state = const OfflineBackupState();
      rethrow;
    } finally {
      keepAliveLink.close();
    }
  }

  Future<bool> restorePrepared() async {
    final snapshot = state.preparedRestore;
    if (state.isWorking || snapshot == null) return false;
    final keepAliveLink = ref.keepAlive();
    state = OfflineBackupState(
      isWorking: true,
      isRestoring: true,
      preparedRestore: snapshot,
    );
    try {
      await TimelineDisplaySettings.waitForPendingSaves();
      await ref.read(restoreOfflineBackupUsecaseProvider).execute(snapshot);
      if (!ref.mounted) return false;
      state = const OfflineBackupState();
      return true;
    } catch (_) {
      if (ref.mounted) {
        state = OfflineBackupState(preparedRestore: snapshot);
      }
      rethrow;
    } finally {
      keepAliveLink.close();
    }
  }
}
