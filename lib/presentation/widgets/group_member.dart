import 'package:flutter/material.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';

enum GroupMemberState { loading, groupList, memberList, empty, error }

class GroupMember extends StatefulWidget {
  final GetGroupsWithMembersUsecase getGroupsWithMembersUsecase;

  const GroupMember({super.key, required this.getGroupsWithMembersUsecase});

  @override
  State<GroupMember> createState() => _GroupMemberState();
}

class _GroupMemberState extends State<GroupMember> {
  GroupMemberState _state = GroupMemberState.loading;
  List<GroupWithMembers> _groupsWithMembers = [];
  GroupWithMembers? _selectedGroup;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (!mounted) return;
      setState(() {
        _state = GroupMemberState.loading;
      });

      final groupsWithMembers = await widget.getGroupsWithMembersUsecase
          .execute();

      if (!mounted) return;
      setState(() {
        _groupsWithMembers = groupsWithMembers;

        if (groupsWithMembers.isEmpty) {
          _state = GroupMemberState.empty;
        } else if (groupsWithMembers.length == 1) {
          _state = GroupMemberState.memberList;
          _selectedGroup = groupsWithMembers.first;
        } else {
          _state = GroupMemberState.groupList;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = GroupMemberState.error;
        _errorMessage = 'エラーが発生しました';
      });
    }
  }

  void _selectGroup(GroupWithMembers group) {
    if (!mounted) return;
    setState(() {
      _selectedGroup = group;
      _state = GroupMemberState.memberList;
    });
  }

  void _backToGroupList() {
    if (!mounted) return;
    setState(() {
      _selectedGroup = null;
      _state = GroupMemberState.groupList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(key: const Key('group_member'), child: _buildBody());
  }

  Widget _buildBody() {
    switch (_state) {
      case GroupMemberState.loading:
        return const Center(child: CircularProgressIndicator());

      case GroupMemberState.empty:
        return _buildEmptyState();

      case GroupMemberState.groupList:
        return _buildGroupList();

      case GroupMemberState.memberList:
        return _buildMemberList();

      case GroupMemberState.error:
        return _buildErrorState();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('グループがありません', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: グループ作成画面への遷移
            },
            child: const Text('グループを作成'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList() {
    return Column(
      children: [
        if (_groupsWithMembers.length > 1)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _backToGroupList,
                ),
                const Text(
                  'グループ一覧',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'グループ一覧',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: _groupsWithMembers.length,
            itemBuilder: (context, index) {
              final groupWithMembers = _groupsWithMembers[index];
              return ListTile(
                title: Text(groupWithMembers.group.name),
                subtitle: Text('${groupWithMembers.members.length}人のメンバー'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _selectGroup(groupWithMembers),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMemberList() {
    if (_selectedGroup == null) return const SizedBox.shrink();

    return Column(
      children: [
        if (_groupsWithMembers.length > 1)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _backToGroupList,
                ),
                Text(
                  _selectedGroup!.group.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _selectedGroup!.group.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        if (_selectedGroup!.members.isEmpty)
          Expanded(child: _buildEmptyMemberState())
        else
          Expanded(
            child: ListView.builder(
              itemCount: _selectedGroup!.members.length,
              itemBuilder: (context, index) {
                final member = _selectedGroup!.members[index];
                return ListTile(
                  title: Text(
                    '${member.kanjiFirstName ?? '未設定'} ${member.kanjiLastName ?? ''}',
                  ),
                  subtitle: Text(member.nickname ?? ''),
                  leading: CircleAvatar(
                    child: Text(
                      member.kanjiFirstName?.isNotEmpty == true
                          ? member.kanjiFirstName![0]
                          : '?',
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyMemberState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('メンバーがいません', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: メンバー追加画面への遷移
            },
            child: const Text('メンバーを追加'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_errorMessage, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('再読み込み')),
        ],
      ),
    );
  }
}
