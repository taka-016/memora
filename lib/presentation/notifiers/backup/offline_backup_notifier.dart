import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/offline_backup_snapshot.dart';
import 'package:memora/composition_root/providers/offline_backup_providers.dart';

class OfflineBackupState extends Equatable {
  const OfflineBackupState({this.isWorking = false, this.preparedRestore});

  final bool isWorking;
  final OfflineBackupSnapshot? preparedRestore;

  @override
  List<Object?> get props => [isWorking, preparedRestore];
}

final offlineBackupNotifierProvider =
    NotifierProvider<OfflineBackupNotifier, OfflineBackupState>(
      OfflineBackupNotifier.new,
    );

class OfflineBackupNotifier extends Notifier<OfflineBackupState> {
  @override
  OfflineBackupState build() => const OfflineBackupState();

  Future<bool> create(String password) async {
    if (state.isWorking) return false;
    state = OfflineBackupState(
      isWorking: true,
      preparedRestore: state.preparedRestore,
    );
    try {
      return await ref
          .read(createOfflineBackupUsecaseProvider)
          .execute(password);
    } finally {
      state = OfflineBackupState(preparedRestore: state.preparedRestore);
    }
  }

  Future<bool> prepareRestore(String password) async {
    if (state.isWorking) return false;
    state = OfflineBackupState(
      isWorking: true,
      preparedRestore: state.preparedRestore,
    );
    try {
      final snapshot = await ref
          .read(prepareOfflineRestoreUsecaseProvider)
          .execute(password);
      state = OfflineBackupState(preparedRestore: snapshot);
      return snapshot != null;
    } catch (_) {
      state = const OfflineBackupState();
      rethrow;
    }
  }

  Future<bool> restorePrepared() async {
    final snapshot = state.preparedRestore;
    if (state.isWorking || snapshot == null) return false;
    state = OfflineBackupState(isWorking: true, preparedRestore: snapshot);
    try {
      await ref.read(restoreOfflineBackupUsecaseProvider).execute(snapshot);
      state = const OfflineBackupState();
      return true;
    } catch (_) {
      state = OfflineBackupState(preparedRestore: snapshot);
      rethrow;
    }
  }
}
