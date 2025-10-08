import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/interfaces/group_query_service.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/application/dtos/group/group_with_members_dto.dart';
import 'package:memora/core/app_logger.dart';

enum GroupListState { loading, groupList, empty, error }

class GroupList extends ConsumerStatefulWidget {
  final Member member;
  final void Function(GroupWithMembersDto)? onGroupSelected;
  final GroupQueryService? groupQueryService;

  const GroupList({
    super.key,
    required this.member,
    this.onGroupSelected,
    this.groupQueryService,
  });

  @override
  ConsumerState<GroupList> createState() => _GroupListState();
}

class _GroupListState extends ConsumerState<GroupList> {
  late final GetGroupsWithMembersUsecase _getGroupsWithMembersUsecase;
  GroupListState _state = GroupListState.loading;
  List<GroupWithMembersDto> _groupsWithMembers = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    final GroupQueryService groupQueryService =
        widget.groupQueryService ?? ref.read(groupQueryServiceProvider);

    _getGroupsWithMembersUsecase = GetGroupsWithMembersUsecase(
      groupQueryService,
    );

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (!mounted) return;
      setState(() {
        _state = GroupListState.loading;
      });

      final groupsWithMembers = await _getGroupsWithMembersUsecase.execute(
        widget.member,
      );

      if (!mounted) return;
      setState(() {
        _groupsWithMembers = groupsWithMembers;

        if (groupsWithMembers.isEmpty) {
          _state = GroupListState.empty;
        } else {
          _state = GroupListState.groupList;
        }
      });
    } catch (e, stack) {
      logger.e(
        'GroupList._loadData: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      if (!mounted) return;
      setState(() {
        _state = GroupListState.error;
        _errorMessage = 'エラーが発生しました';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('group_list'),
      child: _buildContentByState(),
    );
  }

  Widget _buildContentByState() {
    switch (_state) {
      case GroupListState.loading:
        return _buildLoadingState();
      case GroupListState.empty:
        return _buildEmptyState();
      case GroupListState.groupList:
        return _buildGroupListContent();
      case GroupListState.error:
        return _buildErrorState();
    }
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('グループがありません', style: TextStyle(fontSize: 18)),
    );
  }

  Widget _buildGroupListContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildGroupListView()),
      ],
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        'グループ一覧',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildGroupListView() {
    return ListView.builder(
      itemCount: _groupsWithMembers.length,
      itemBuilder: (context, index) => _buildGroupListItem(index),
    );
  }

  Widget _buildGroupListItem(int index) {
    final groupWithMembers = _groupsWithMembers[index];
    return ListTile(
      title: Text(groupWithMembers.groupName),
      subtitle: Text('${groupWithMembers.members.length}人のメンバー'),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => widget.onGroupSelected?.call(groupWithMembers),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildErrorMessage(),
          const SizedBox(height: 16),
          _buildRetryButton(),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Text(_errorMessage, style: const TextStyle(fontSize: 18));
  }

  Widget _buildRetryButton() {
    return ElevatedButton(onPressed: _loadData, child: const Text('再読み込み'));
  }
}
