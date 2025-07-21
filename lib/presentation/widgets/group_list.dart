import 'package:flutter/material.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/domain/entities/member.dart';

enum GroupListState { loading, groupList, empty, error }

class GroupList extends StatefulWidget {
  final GetGroupsWithMembersUsecase getGroupsWithMembersUsecase;
  final Member member;
  final void Function(GroupWithMembers)? onGroupSelected;

  const GroupList({
    super.key,
    required this.getGroupsWithMembersUsecase,
    required this.member,
    this.onGroupSelected,
  });

  @override
  State<GroupList> createState() => _GroupListState();
}

class _GroupListState extends State<GroupList> {
  GroupListState _state = GroupListState.loading;
  List<GroupWithMembers> _groupsWithMembers = [];
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
        _state = GroupListState.loading;
      });

      final groupsWithMembers = await widget.getGroupsWithMembersUsecase
          .execute(widget.member);

      if (!mounted) return;
      setState(() {
        _groupsWithMembers = groupsWithMembers;

        if (groupsWithMembers.isEmpty) {
          _state = GroupListState.empty;
        } else {
          _state = GroupListState.groupList;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = GroupListState.error;
        _errorMessage = 'エラーが発生しました';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(key: const Key('group_member'), child: _buildBody());
  }

  Widget _buildBody() {
    switch (_state) {
      case GroupListState.loading:
        return const Center(child: CircularProgressIndicator());

      case GroupListState.empty:
        return _buildEmptyState();

      case GroupListState.groupList:
        return _buildGroupList();

      case GroupListState.error:
        return _buildErrorState();
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('グループがありません', style: TextStyle(fontSize: 18)),
    );
  }

  Widget _buildGroupList() {
    return Column(
      children: [
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
                onTap: () {
                  widget.onGroupSelected?.call(groupWithMembers);
                },
              );
            },
          ),
        ),
      ],
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
