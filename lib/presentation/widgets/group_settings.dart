import 'package:flutter/material.dart';
import '../../application/usecases/get_managed_groups_usecase.dart';
import '../../application/usecases/delete_group_usecase.dart';
import '../../domain/entities/member.dart';
import '../../domain/entities/group.dart';
import '../../domain/repositories/group_repository.dart';
import '../../infrastructure/repositories/firestore_group_repository.dart';

class GroupSettings extends StatefulWidget {
  final Member member;
  final GroupRepository? groupRepository;

  const GroupSettings({super.key, required this.member, this.groupRepository});

  @override
  State<GroupSettings> createState() => _GroupSettingsState();
}

class _GroupSettingsState extends State<GroupSettings> {
  late final GetManagedGroupsUsecase _getManagedGroupsUsecase;
  late final DeleteGroupUsecase _deleteGroupUsecase;

  List<Group> _managedGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // 注入されたリポジトリまたはデフォルトのFirestoreリポジトリを使用
    final groupRepository =
        widget.groupRepository ?? FirestoreGroupRepository();

    _getManagedGroupsUsecase = GetManagedGroupsUsecase(groupRepository);
    _deleteGroupUsecase = DeleteGroupUsecase(groupRepository);

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final managedGroups = await _getManagedGroupsUsecase.execute(
        widget.member,
      );
      _managedGroups = managedGroups;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('データの読み込みに失敗しました: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteGroup(Group group) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループ削除'),
        content: Text('${group.name}を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _deleteGroupUsecase.execute(group.id);
        if (mounted) {
          await _loadData();
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('グループを削除しました')),
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('group_settings'),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.group_work, size: 32),
                      const SizedBox(width: 16),
                      const Text(
                        'グループ設定',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => {},
                        icon: const Icon(Icons.add),
                        label: const Text('グループ追加'),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _managedGroups.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.group_work,
                                size: 100,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                '管理しているグループがありません',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'グループを追加してください',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            itemCount: _managedGroups.length,
                            itemBuilder: (context, index) {
                              final group = _managedGroups[index];

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text(group.name.substring(0, 1)),
                                  ),
                                  title: Text(group.name),
                                  subtitle: group.memo != null
                                      ? Text(group.memo!)
                                      : null,
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteGroup(group),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
