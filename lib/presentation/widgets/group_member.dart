import 'package:flutter/material.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/domain/entities/member.dart';

enum GroupMemberState { loading, groupList, empty, error }

class GroupMember extends StatefulWidget {
  final GetGroupsWithMembersUsecase getGroupsWithMembersUsecase;
  final Member member;

  const GroupMember({
    super.key,
    required this.getGroupsWithMembersUsecase,
    required this.member,
  });

  @override
  State<GroupMember> createState() => _GroupMemberState();
}

class _GroupMemberState extends State<GroupMember> {
  GroupMemberState _state = GroupMemberState.loading;
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
        _state = GroupMemberState.loading;
      });

      final groupsWithMembers = await widget.getGroupsWithMembersUsecase
          .execute(widget.member);

      if (!mounted) return;
      setState(() {
        _groupsWithMembers = groupsWithMembers;

        if (groupsWithMembers.isEmpty) {
          _state = GroupMemberState.empty;
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

      case GroupMemberState.error:
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
