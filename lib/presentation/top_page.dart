import 'package:flutter/material.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';

enum TopPageState { loading, groupList, memberList, empty, error }

class TopPage extends StatefulWidget {
  final GetGroupsWithMembersUsecase getGroupsWithMembersUsecase;

  const TopPage({
    super.key,
    required this.getGroupsWithMembersUsecase,
  });

  @override
  State<TopPage> createState() => _TopPageState();
}

class _TopPageState extends State<TopPage> {
  TopPageState _state = TopPageState.loading;
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
      setState(() {
        _state = TopPageState.loading;
      });

      final groupsWithMembers = await widget.getGroupsWithMembersUsecase.execute();
      
      setState(() {
        _groupsWithMembers = groupsWithMembers;
        
        if (groupsWithMembers.isEmpty) {
          _state = TopPageState.empty;
        } else if (groupsWithMembers.length == 1) {
          _state = TopPageState.memberList;
          _selectedGroup = groupsWithMembers.first;
        } else {
          _state = TopPageState.groupList;
        }
      });
    } catch (e) {
      setState(() {
        _state = TopPageState.error;
        _errorMessage = 'エラーが発生しました';
      });
    }
  }

  void _selectGroup(GroupWithMembers group) {
    setState(() {
      _selectedGroup = group;
      _state = TopPageState.memberList;
    });
  }

  void _backToGroupList() {
    setState(() {
      _selectedGroup = null;
      _state = TopPageState.groupList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('memora'),
        leading: _state == TopPageState.memberList && _groupsWithMembers.length > 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _backToGroupList,
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case TopPageState.loading:
        return const Center(child: CircularProgressIndicator());
      
      case TopPageState.empty:
        return _buildEmptyState();
      
      case TopPageState.groupList:
        return _buildGroupList();
      
      case TopPageState.memberList:
        return _buildMemberList();
      
      case TopPageState.error:
        return _buildErrorState();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'グループがありません',
            style: TextStyle(fontSize: 18),
          ),
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
                  title: Text('${member.kanjiFirstName} ${member.kanjiLastName}'),
                  subtitle: Text(member.nickname ?? ''),
                  leading: CircleAvatar(
                    child: Text(member.kanjiFirstName[0]),
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
          const Text(
            'メンバーがいません',
            style: TextStyle(fontSize: 18),
          ),
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
          Text(
            _errorMessage,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('再読み込み'),
          ),
        ],
      ),
    );
  }
}