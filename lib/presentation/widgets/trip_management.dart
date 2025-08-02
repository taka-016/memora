import 'package:flutter/material.dart';
import '../../application/usecases/create_trip_entry_usecase.dart';
import '../../application/usecases/get_trip_entries_usecase.dart';
import '../../application/usecases/update_trip_entry_usecase.dart';
import '../../application/usecases/delete_trip_entry_usecase.dart';
import '../../domain/entities/trip_entry.dart';
import '../../domain/repositories/trip_entry_repository.dart';
import '../../infrastructure/repositories/firestore_trip_entry_repository.dart';
import 'trip_edit_modal.dart';

class TripManagement extends StatefulWidget {
  final String groupId;
  final int year;
  final VoidCallback? onBackPressed;
  final TripEntryRepository? tripEntryRepository;
  final bool isTestEnvironment;

  const TripManagement({
    super.key,
    required this.groupId,
    required this.year,
    this.onBackPressed,
    this.tripEntryRepository,
    this.isTestEnvironment = false,
  });

  @override
  State<TripManagement> createState() => _TripManagementState();
}

class _TripManagementState extends State<TripManagement> {
  late final GetTripEntriesUsecase _getTripEntriesUsecase;
  late final CreateTripEntryUsecase _createTripEntryUsecase;
  late final UpdateTripEntryUsecase _updateTripEntryUsecase;
  late final DeleteTripEntryUsecase _deleteTripEntryUsecase;

  List<TripEntry> _tripEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // 注入されたリポジトリまたはデフォルトのFirestoreリポジトリを使用
    final tripEntryRepository =
        widget.tripEntryRepository ?? FirestoreTripEntryRepository();

    _getTripEntriesUsecase = GetTripEntriesUsecase(tripEntryRepository);
    _createTripEntryUsecase = CreateTripEntryUsecase(tripEntryRepository);
    _updateTripEntryUsecase = UpdateTripEntryUsecase(tripEntryRepository);
    _deleteTripEntryUsecase = DeleteTripEntryUsecase(tripEntryRepository);

    _loadTripEntries();
  }

  Future<void> _loadTripEntries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tripEntries = await _getTripEntriesUsecase.execute(
        widget.groupId,
        widget.year,
      );
      _tripEntries = tripEntries;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('旅行一覧の読み込みに失敗しました: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  Future<void> _showAddTripDialog() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (context) => TripEditModal(
        groupId: widget.groupId,
        isTestEnvironment: widget.isTestEnvironment,
        onSave: (tripEntry) async {
          try {
            await _createTripEntryUsecase.execute(tripEntry);
            if (mounted) {
              await _loadTripEntries();
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('旅行を作成しました')),
              );
            }
          } catch (e) {
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('作成に失敗しました: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _showEditTripDialog(TripEntry tripEntry) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (context) => TripEditModal(
        groupId: widget.groupId,
        tripEntry: tripEntry,
        isTestEnvironment: widget.isTestEnvironment,
        onSave: (updatedTripEntry) async {
          try {
            await _updateTripEntryUsecase.execute(updatedTripEntry);
            if (mounted) {
              await _loadTripEntries();
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('旅行を更新しました')),
              );
            }
          } catch (e) {
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('更新に失敗しました: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmDialog(TripEntry tripEntry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('旅行削除'),
        content: Text('「${tripEntry.tripName ?? '旅行名未設定'}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteTripEntry(tripEntry);
    }
  }

  Future<void> _deleteTripEntry(TripEntry tripEntry) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await _deleteTripEntryUsecase.execute(tripEntry.id);
      if (mounted) {
        await _loadTripEntries();
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('${tripEntry.tripName}を削除しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('trip_management'),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (widget.onBackPressed != null)
                      IconButton(
                        key: const Key('back_button'),
                        icon: const Icon(Icons.arrow_back),
                        onPressed: widget.onBackPressed,
                      ),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(width: 16),
                    Text(
                      '${widget.year}年の旅行管理',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _showAddTripDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('旅行追加'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadTripEntries,
      child: _tripEntries.isEmpty
          ? const Center(
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
            )
          : ListView.builder(
              itemCount: _tripEntries.length,
              itemBuilder: (context, index) {
                final tripEntry = _tripEntries[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(tripEntry.tripName ?? '旅行名未設定'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_formatDate(tripEntry.tripStartDate)} - ${_formatDate(tripEntry.tripEndDate)}',
                        ),
                        if (tripEntry.tripMemo != null)
                          Text(
                            tripEntry.tripMemo!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmDialog(tripEntry),
                    ),
                    onTap: () => _showEditTripDialog(tripEntry),
                  ),
                );
              },
            ),
    );
  }
}
