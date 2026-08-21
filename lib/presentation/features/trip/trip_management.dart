import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/usecases/trip/get_trip_entry_by_id_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/features/trip/trip_edit_modal.dart';
import 'package:memora/presentation/notifiers/trip_management_notifier.dart';
import 'package:memora/presentation/shared/dialogs/delete_confirm_dialog.dart';

class TripManagement extends HookConsumerWidget {
  final String groupId;
  final int year;
  final String? initialTripId;
  final VoidCallback? onBackPressed;
  final bool isTestEnvironment;

  const TripManagement({
    super.key,
    required this.groupId,
    required this.year,
    this.initialTripId,
    this.onBackPressed,
    this.isTestEnvironment = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managementProvider = tripManagementNotifierProvider(
      TripManagementQuery(groupId: groupId, year: year),
    );
    final managementState = ref.watch(managementProvider);
    final managementNotifier = ref.read(managementProvider.notifier);
    final getTripEntryByIdUsecase = ref.read(getTripEntryByIdUsecaseProvider);

    final isOpeningInitialTrip = useState(false);
    final isShowingInitialTripDialog = useState(false);
    final initialTripHandled = useRef(false);
    final initialTripDialogReady = useRef(initialTripId == null);
    final isTripDialogInProgress = useRef(false);
    final activeTripDetailId = useRef<String?>(null);
    final tripDetailRequestId = useRef(0);
    final tripDialogScope = useRef((groupId, year, initialTripId));
    final currentTripDialogScope = (groupId, year, initialTripId);
    if (tripDialogScope.value != currentTripDialogScope) {
      tripDialogScope.value = currentTripDialogScope;
      tripDetailRequestId.value++;
      activeTripDetailId.value = null;
      isTripDialogInProgress.value = false;
    }

    ref.listen<TripManagementState>(managementProvider, (previous, next) {
      if (next.tripEntriesStatus == TripManagementLoadStatus.error &&
          previous?.tripEntriesStatus != TripManagementLoadStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('旅行一覧の読み込みに失敗しました: ${next.tripEntriesError}')),
        );
      }
      if (next.groupMembersStatus == TripManagementLoadStatus.error &&
          previous?.groupMembersStatus != TripManagementLoadStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('グループメンバーの読み込みに失敗しました: ${next.groupMembersError}'),
          ),
        );
      }
    });

    String formatDate(DateTime? date) {
      if (date == null) {
        return '未設定';
      }
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      return '${date.year}/$month/$day';
    }

    String buildTripPeriodLabel(TripEntryDto tripEntry) {
      final hasStart = tripEntry.startDate != null;
      final hasEnd = tripEntry.endDate != null;
      if (!hasStart && !hasEnd) {
        return '${tripEntry.year}年 (期間未設定)';
      }
      final startLabel = hasStart ? formatDate(tripEntry.startDate) : '未設定';
      final endLabel = hasEnd ? formatDate(tripEntry.endDate) : '未設定';
      return '$startLabel - $endLabel';
    }

    Future<void> handleAddTripSave(TripEntryDto tripEntry) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        final succeeded = await managementNotifier.createTripEntry(tripEntry);
        if (!context.mounted || !succeeded) {
          return;
        }
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('旅行を作成しました')),
        );
      } on ApplicationValidationException {
        rethrow;
      } catch (e, stack) {
        logger.e(
          'TripManagement.handleAddTripSave: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('作成に失敗しました: $e')),
          );
        }
      }
    }

    Future<void> showAddTripDialog() async {
      if (isTripDialogInProgress.value) {
        return;
      }
      isTripDialogInProgress.value = true;
      try {
        await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (dialogContext) => TripEditModal(
            groupId: groupId,
            groupMembers: managementState.groupMembers,
            year: year,
            isTestEnvironment: isTestEnvironment,
            onSave: (tripEntry) async {
              await handleAddTripSave(tripEntry);
            },
          ),
        );
      } finally {
        isTripDialogInProgress.value = false;
      }
    }

    Future<void> handleEditTripSave(TripEntryDto tripEntry) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        final succeeded = await managementNotifier.updateTripEntry(tripEntry);
        if (!context.mounted || !succeeded) {
          return;
        }
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('旅行を更新しました')),
        );
      } on ApplicationValidationException {
        rethrow;
      } catch (e, stack) {
        logger.e(
          'TripManagement.handleEditTripSave: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('更新に失敗しました: $e')),
          );
        }
      }
    }

    Future<void> showEditTripDialog(
      String tripId, {
      VoidCallback? onBeforeShowDialog,
    }) async {
      if (isTripDialogInProgress.value &&
          (activeTripDetailId.value == null ||
              activeTripDetailId.value == tripId)) {
        return;
      }
      final requestId = ++tripDetailRequestId.value;
      activeTripDetailId.value = tripId;
      isTripDialogInProgress.value = true;
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        final detailedTripEntry = await getTripEntryByIdUsecase.execute(tripId);

        if (!context.mounted || requestId != tripDetailRequestId.value) {
          return;
        }

        if (detailedTripEntry == null ||
            detailedTripEntry.groupId != groupId ||
            detailedTripEntry.year != year) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('旅行の詳細取得に失敗しました: データが見つかりませんでした')),
          );
          return;
        }

        onBeforeShowDialog?.call();
        await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (dialogContext) => TripEditModal(
            groupId: groupId,
            groupMembers: managementState.groupMembers,
            tripEntry: detailedTripEntry,
            year: year,
            isTestEnvironment: isTestEnvironment,
            onSave: (updatedTrip) async {
              await handleEditTripSave(updatedTrip);
            },
          ),
        );
      } catch (e, stack) {
        if (requestId != tripDetailRequestId.value) {
          return;
        }
        logger.e(
          'TripManagement.showEditTripDialog: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('旅行の詳細取得に失敗しました: $e')),
          );
        }
      } finally {
        if (requestId == tripDetailRequestId.value) {
          activeTripDetailId.value = null;
          isTripDialogInProgress.value = false;
        }
      }
    }

    useEffect(() {
      initialTripHandled.value = false;
      initialTripDialogReady.value = initialTripId == null;
      return null;
    }, [groupId, year, initialTripId]);

    useEffect(() {
      final tripId = initialTripId;
      if (tripId == null ||
          managementState.isInitialLoading ||
          initialTripHandled.value) {
        return null;
      }
      Future<void> showInitialTripDialog() async {
        isOpeningInitialTrip.value = true;
        try {
          await showEditTripDialog(
            tripId,
            onBeforeShowDialog: () {
              isShowingInitialTripDialog.value = true;
              isOpeningInitialTrip.value = false;
            },
          );
        } finally {
          if (context.mounted) {
            initialTripDialogReady.value = true;
            if (isShowingInitialTripDialog.value) {
              isShowingInitialTripDialog.value = false;
            }
            if (isOpeningInitialTrip.value) {
              isOpeningInitialTrip.value = false;
            }
          }
        }
      }

      initialTripHandled.value = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          unawaited(showInitialTripDialog());
        }
      });
      return null;
    }, [initialTripId, managementState.isInitialLoading, groupId, year]);

    Future<void> deleteTripEntry(TripEntryDto tripEntry) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        final succeeded = await managementNotifier.deleteTripEntry(
          tripEntry.id,
        );
        if (!context.mounted || !succeeded) {
          return;
        }
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('${tripEntry.name}を削除しました')),
        );
      } catch (e, stack) {
        logger.e(
          'TripManagement.deleteTripEntry: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('削除に失敗しました: $e')),
          );
        }
      }
    }

    Future<void> showDeleteConfirmDialog(TripEntryDto tripEntry) async {
      if (isTripDialogInProgress.value) {
        return;
      }
      isTripDialogInProgress.value = true;
      try {
        await DeleteConfirmDialog.show(
          context,
          title: '旅行削除',
          content: '「${tripEntry.name ?? '旅行名未設定'}」を削除しますか？',
          onConfirm: () async => deleteTripEntry(tripEntry),
        );
      } finally {
        isTripDialogInProgress.value = false;
      }
    }

    Widget buildBackButton() {
      return Row(
        children: [
          if (onBackPressed != null)
            IconButton(
              key: const Key('back_button'),
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed,
            ),
        ],
      );
    }

    Widget buildHeader() {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildBackButton(),
            Row(
              children: [
                const SizedBox(width: 16),
                Text(
                  '$year年の旅行管理',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed:
                      managementState.groupMembersStatus ==
                          TripManagementLoadStatus.success
                      ? showAddTripDialog
                      : null,
                  icon: const Icon(Icons.add),
                  label: const Text('旅行追加'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget buildEmptyState() {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flight_takeoff, size: 100, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'この年の旅行はまだありません',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '旅行を追加してください',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    Widget buildTripSubtitle(TripEntryDto tripEntry) {
      final memo = tripEntry.memo?.trim();
      final memoText = memo ?? '';
      final hasMemo = memoText.isNotEmpty;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(buildTripPeriodLabel(tripEntry)),
          if (hasMemo)
            Text(memoText, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      );
    }

    Widget buildTripListView() {
      return ListView.builder(
        itemCount: managementState.tripEntries.length,
        itemBuilder: (context, index) {
          final tripEntry = managementState.tripEntries[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(tripEntry.name ?? '旅行名未設定'),
              subtitle: buildTripSubtitle(tripEntry),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => showDeleteConfirmDialog(tripEntry),
              ),
              onTap: () => showEditTripDialog(tripEntry.id),
            ),
          );
        },
      );
    }

    Widget buildLoadError({
      required String message,
      required Key retryButtonKey,
      required VoidCallback onRetry,
    }) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text(message)),
            const SizedBox(width: 8),
            TextButton(
              key: retryButtonKey,
              onPressed: onRetry,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    Widget buildTripListContent() {
      final listContent = managementState.tripEntries.isEmpty
          ? buildEmptyState()
          : RefreshIndicator(
              onRefresh: () async {
                await managementNotifier.retryTripEntries();
              },
              child: buildTripListView(),
            );
      if (managementState.tripEntriesStatus != TripManagementLoadStatus.error) {
        return listContent;
      }
      return Column(
        children: [
          buildLoadError(
            message: '旅行一覧を読み込めませんでした',
            retryButtonKey: const Key('trip_entries_retry_button'),
            onRetry: () {
              unawaited(managementNotifier.retryTripEntries());
            },
          ),
          Expanded(child: listContent),
        ],
      );
    }

    Widget buildLoadingState() {
      return const Center(child: CircularProgressIndicator());
    }

    Widget buildInitialTripBackdrop() {
      return const SizedBox.expand();
    }

    Widget buildContent() {
      final shouldHideForInitialTrip =
          initialTripId != null &&
          (!initialTripDialogReady.value || isOpeningInitialTrip.value);
      if (shouldHideForInitialTrip && isShowingInitialTripDialog.value) {
        return buildInitialTripBackdrop();
      }
      if (managementState.isInitialLoading || shouldHideForInitialTrip) {
        return buildLoadingState();
      }

      return Column(
        children: [
          buildHeader(),
          const Divider(),
          if (managementState.groupMembersStatus ==
              TripManagementLoadStatus.error)
            buildLoadError(
              message: 'グループメンバーを読み込めませんでした',
              retryButtonKey: const Key('group_members_retry_button'),
              onRetry: () {
                unawaited(managementNotifier.retryGroupMembers());
              },
            ),
          Expanded(child: buildTripListContent()),
        ],
      );
    }

    return Container(key: const Key('trip_management'), child: buildContent());
  }
}
