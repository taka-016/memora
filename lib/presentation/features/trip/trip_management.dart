import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/usecases/trip/create_trip_entry_usecase.dart';
import 'package:memora/application/usecases/trip/delete_trip_entry_usecase.dart';
import 'package:memora/application/usecases/trip/get_trip_entries_usecase.dart';
import 'package:memora/application/usecases/trip/get_trip_entry_by_id_usecase.dart';
import 'package:memora/application/usecases/trip/update_trip_entry_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/presentation/features/trip/trip_edit_modal.dart';
import 'package:memora/presentation/shared/dialogs/delete_confirm_dialog.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

class TripManagement extends HookConsumerWidget {
  final String groupId;
  final int year;
  final VoidCallback? onBackPressed;
  final bool isTestEnvironment;

  const TripManagement({
    super.key,
    required this.groupId,
    required this.year,
    this.onBackPressed,
    this.isTestEnvironment = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getTripEntriesUsecase = ref.read(getTripEntriesUsecaseProvider);
    final createTripEntryUsecase = ref.read(createTripEntryUsecaseProvider);
    final updateTripEntryUsecase = ref.read(updateTripEntryUsecaseProvider);
    final deleteTripEntryUsecase = ref.read(deleteTripEntryUsecaseProvider);
    final getTripEntryByIdUsecase = ref.read(getTripEntryByIdUsecaseProvider);
    final groupQueryService = ref.read(groupQueryServiceProvider);

    final tripEntries = useState<List<TripEntryDto>>([]);
    final isLoading = useState(true);
    final assignableMembers = useState<List<GroupMemberDto>>([]);

    Future<void> loadTripEntries() async {
      isLoading.value = true;

      try {
        final data = await getTripEntriesUsecase.execute(groupId, year);
        tripEntries.value = data;
      } catch (e, stack) {
        logger.e(
          'TripManagement.loadTripEntries: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('旅行一覧の読み込みに失敗しました: $e')));
        }
      } finally {
        if (context.mounted) {
          isLoading.value = false;
        }
      }
    }

    Future<void> loadGroupMembers() async {
      try {
        final group = await groupQueryService.getGroupWithMembersById(
          groupId,
          membersOrderBy: [const OrderBy('displayName', descending: false)],
        );
        assignableMembers.value = group?.members ?? [];
      } catch (e, stack) {
        logger.e(
          'TripManagement.loadGroupMembers: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('メンバー取得に失敗しました: $e')));
      }
    }

    useEffect(() {
      loadTripEntries();
      loadGroupMembers();
      return null;
    }, [groupId, year]);

    String formatDate(DateTime? date) {
      if (date == null) {
        return '未設定';
      }
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      return '${date.year}/$month/$day';
    }

    String buildTripPeriodLabel(TripEntryDto tripEntry) {
      final hasStart = tripEntry.tripStartDate != null;
      final hasEnd = tripEntry.tripEndDate != null;
      if (!hasStart && !hasEnd) {
        return '${tripEntry.tripYear}年 (期間未設定)';
      }
      final startLabel = hasStart ? formatDate(tripEntry.tripStartDate) : '未設定';
      final endLabel = hasEnd ? formatDate(tripEntry.tripEndDate) : '未設定';
      return '$startLabel - $endLabel';
    }

    Future<void> handleAddTripSave(TripEntry tripEntry) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        await createTripEntryUsecase.execute(tripEntry);
        if (!context.mounted) {
          return;
        }
        await loadTripEntries();
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('旅行を作成しました')),
        );
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
      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (dialogContext) => TripEditModal(
          groupId: groupId,
          year: year,
          isTestEnvironment: isTestEnvironment,
          assignableMembers: assignableMembers.value,
          onSave: (tripEntry) async {
            await handleAddTripSave(tripEntry);
          },
        ),
      );
    }

    Future<void> handleEditTripSave(TripEntry tripEntry) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        await updateTripEntryUsecase.execute(tripEntry);
        if (!context.mounted) {
          return;
        }
        await loadTripEntries();
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('旅行を更新しました')),
        );
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

    Future<void> showEditTripDialog(TripEntryDto tripEntry) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        final detailedTripEntry = await getTripEntryByIdUsecase.execute(
          tripEntry.id,
        );

        if (!context.mounted) {
          return;
        }

        if (detailedTripEntry == null) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('旅行の詳細取得に失敗しました: データが見つかりませんでした')),
          );
          return;
        }

        await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (dialogContext) => TripEditModal(
            groupId: groupId,
            tripEntry: detailedTripEntry,
            year: year,
            isTestEnvironment: isTestEnvironment,
            assignableMembers: assignableMembers.value,
            onSave: (updatedTrip) async {
              await handleEditTripSave(updatedTrip);
            },
          ),
        );
      } catch (e, stack) {
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
      }
    }

    Future<void> deleteTripEntry(TripEntryDto tripEntry) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        await deleteTripEntryUsecase.execute(tripEntry.id);
        if (!context.mounted) {
          return;
        }
        await loadTripEntries();
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('${tripEntry.tripName}を削除しました')),
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
      await DeleteConfirmDialog.show(
        context,
        title: '旅行削除',
        content: '「${tripEntry.tripName ?? '旅行名未設定'}」を削除しますか？',
        onConfirm: () async => deleteTripEntry(tripEntry),
      );
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
                  onPressed: showAddTripDialog,
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(buildTripPeriodLabel(tripEntry)),
          if (tripEntry.tripMemo != null)
            Text(
              tripEntry.tripMemo!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      );
    }

    Widget buildTripListView() {
      return ListView.builder(
        itemCount: tripEntries.value.length,
        itemBuilder: (context, index) {
          final tripEntry = tripEntries.value[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(tripEntry.tripName ?? '旅行名未設定'),
              subtitle: buildTripSubtitle(tripEntry),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => showDeleteConfirmDialog(tripEntry),
              ),
              onTap: () => showEditTripDialog(tripEntry),
            ),
          );
        },
      );
    }

    Widget buildTripListContent() {
      if (tripEntries.value.isEmpty) {
        return buildEmptyState();
      }
      return RefreshIndicator(
        onRefresh: loadTripEntries,
        child: buildTripListView(),
      );
    }

    Widget buildLoadingState() {
      return const Center(child: CircularProgressIndicator());
    }

    Widget buildContent() {
      if (isLoading.value) {
        return buildLoadingState();
      }

      return Column(
        children: [
          buildHeader(),
          const Divider(),
          Expanded(child: buildTripListContent()),
        ],
      );
    }

    return Container(key: const Key('trip_management'), child: buildContent());
  }
}
