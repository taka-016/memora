import 'package:flutter/material.dart';
import '../../domain/entities/trip_entry.dart';
import 'trip_edit_modal.dart';

class TripManagement extends StatefulWidget {
  final String groupId;
  final int year;
  final VoidCallback? onBackPressed;

  const TripManagement({
    super.key,
    required this.groupId,
    required this.year,
    this.onBackPressed,
  });

  @override
  State<TripManagement> createState() => _TripManagementState();
}

class _TripManagementState extends State<TripManagement> {
  List<TripEntry> _tripEntries = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTripEntries();
  }

  Future<void> _loadTripEntries() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // TODO: 実際のUseCaseを使って旅行一覧を取得する
      // 今は空のリストで初期化
      setState(() {
        _tripEntries = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '旅行一覧の読み込みに失敗しました: $e';
        _isLoading = false;
      });
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

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTripEntries,
              child: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }

    if (_tripEntries.isEmpty) {
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

    return ListView.builder(
      itemCount: _tripEntries.length,
      itemBuilder: (context, index) {
        final tripEntry = _tripEntries[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditTripDialog(tripEntry),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmDialog(tripEntry),
                ),
              ],
            ),
            onTap: () => _showEditTripDialog(tripEntry),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  void _showAddTripDialog() {
    showDialog(
      context: context,
      builder: (context) => TripEditModal(
        groupId: widget.groupId,
        onSave: (tripEntry) {
          // TODO: 実際の保存処理を実装
        },
      ),
    );
  }

  void _showEditTripDialog(TripEntry tripEntry) {
    showDialog(
      context: context,
      builder: (context) => TripEditModal(
        groupId: widget.groupId,
        tripEntry: tripEntry,
        onSave: (updatedTripEntry) {
          // TODO: 実際の更新処理を実装
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(TripEntry tripEntry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認'),
        content: Text('「${tripEntry.tripName ?? '旅行名未設定'}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTripEntry(tripEntry);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  void _deleteTripEntry(TripEntry tripEntry) {
    // TODO: 実際の削除処理を実装
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${tripEntry.tripName}を削除しました')));

    setState(() {
      _tripEntries.remove(tripEntry);
    });
  }
}
