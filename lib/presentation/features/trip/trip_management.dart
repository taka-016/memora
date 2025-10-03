import 'package:flutter/material.dart';
import 'package:memora/application/mappers/pin_mapper.dart';
import 'package:memora/application/usecases/trip/create_trip_entry_usecase.dart';
import 'package:memora/application/usecases/trip/get_trip_entries_usecase.dart';
import 'package:memora/application/usecases/trip/update_trip_entry_usecase.dart';
import 'package:memora/application/usecases/trip/get_trip_entry_by_id_usecase.dart';
import 'package:memora/application/usecases/trip/delete_trip_entry_usecase.dart';
import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';
import 'package:memora/infrastructure/repositories/firestore_trip_entry_repository.dart';
import 'package:memora/presentation/shared/dialogs/delete_confirm_dialog.dart';
import 'trip_edit_modal.dart';
import 'package:memora/core/app_logger.dart';

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
  late final GetTripEntryByIdUsecase _getTripEntryByIdUsecase;

  List<TripEntry> _tripEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    final tripEntryRepository =
        widget.tripEntryRepository ?? FirestoreTripEntryRepository();

    _getTripEntriesUsecase = GetTripEntriesUsecase(tripEntryRepository);
    _createTripEntryUsecase = CreateTripEntryUsecase(tripEntryRepository);
    _updateTripEntryUsecase = UpdateTripEntryUsecase(tripEntryRepository);
    _deleteTripEntryUsecase = DeleteTripEntryUsecase(tripEntryRepository);
    _getTripEntryByIdUsecase = GetTripEntryByIdUsecase(tripEntryRepository);

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
    } catch (e, stack) {
      logger.e(
        '_TripManagementState._loadTripEntries: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
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

  Future<void> _handleAddTripSave(TripEntry tripEntry) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await _createTripEntryUsecase.execute(tripEntry);

      if (mounted) {
        await _loadTripEntries();
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('旅行を作成しました')),
        );
      }
    } catch (e, stack) {
      logger.e(
        '_TripManagementState._handleAddTripSave: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('作成に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _showAddTripDialog() async {
    await showDialog(
      context: context,
      builder: (context) => TripEditModal(
        groupId: widget.groupId,
        year: widget.year,
        isTestEnvironment: widget.isTestEnvironment,
        onSave: _handleAddTripSave,
      ),
    );
  }

  Future<void> _handleEditTripSave(TripEntry tripEntry) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await _updateTripEntryUsecase.execute(tripEntry);

      if (mounted) {
        await _loadTripEntries();
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('旅行を更新しました')),
        );
      }
    } catch (e, stack) {
      logger.e(
        '_TripManagementState._handleEditTripSave: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('更新に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _showEditTripDialog(TripEntry tripEntry) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final detailedTripEntry = await _getTripEntryByIdUsecase.execute(
        tripEntry.id,
      );

      if (!mounted) {
        return;
      }

      if (detailedTripEntry == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('旅行の詳細取得に失敗しました: データが見つかりませんでした')),
        );
        return;
      }

      final existingPins = PinMapper.toDtoList(detailedTripEntry.pins);

      await showDialog(
        context: context,
        builder: (context) => TripEditModal(
          groupId: widget.groupId,
          tripEntry: detailedTripEntry,
          pins: existingPins,
          year: widget.year,
          isTestEnvironment: widget.isTestEnvironment,
          onSave: _handleEditTripSave,
        ),
      );
    } catch (e, stack) {
      logger.e(
        '_TripManagementState._showEditTripDialog: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      if (!mounted) {
        return;
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('旅行の詳細取得に失敗しました: $e')),
      );
    }
  }

  Future<void> _showDeleteConfirmDialog(TripEntry tripEntry) async {
    await DeleteConfirmDialog.show(
      context,
      title: '旅行削除',
      content: '「${tripEntry.tripName ?? '旅行名未設定'}」を削除しますか？',
      onConfirm: () async => await _deleteTripEntry(tripEntry),
    );
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
    } catch (e, stack) {
      logger.e(
        '_TripManagementState._deleteTripEntry: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
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
          _buildHeader(),
          const Divider(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildBackButton(), _buildTitleSection()],
      ),
    );
  }

  Widget _buildBackButton() {
    return Row(
      children: [
        if (widget.onBackPressed != null)
          IconButton(
            key: const Key('back_button'),
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBackPressed,
          ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Row(
      children: [
        const SizedBox(width: 16),
        Text(
          '${widget.year}年の旅行管理',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        _buildAddTripButton(),
      ],
    );
  }

  Widget _buildAddTripButton() {
    return ElevatedButton.icon(
      onPressed: _showAddTripDialog,
      icon: const Icon(Icons.add),
      label: const Text('旅行追加'),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return RefreshIndicator(
      onRefresh: _loadTripEntries,
      child: _tripEntries.isEmpty ? _buildEmptyState() : _buildTripList(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState() {
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

  Widget _buildTripList() {
    return ListView.builder(
      itemCount: _tripEntries.length,
      itemBuilder: (context, index) {
        final tripEntry = _tripEntries[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(tripEntry.tripName ?? '旅行名未設定'),
            subtitle: _buildTripSubtitle(tripEntry),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmDialog(tripEntry),
            ),
            onTap: () => _showEditTripDialog(tripEntry),
          ),
        );
      },
    );
  }

  Widget _buildTripSubtitle(TripEntry tripEntry) {
    return Column(
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
    );
  }
}
