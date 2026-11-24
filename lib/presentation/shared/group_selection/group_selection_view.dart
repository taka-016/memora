import 'package:flutter/material.dart';
import 'package:memora/application/dtos/group/group_dto.dart';

class GroupSelectionView extends StatelessWidget {
  const GroupSelectionView({
    super.key,
    required this.groups,
    required this.onGroupSelected,
    required this.onRefresh,
  });

  final List<GroupDto> groups;
  final ValueChanged<GroupDto> onGroupSelected;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: constraints.maxHeight,
                child: const Center(
                  child: Text('グループがありません', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'グループを選択',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return ListTile(
                  title: Text(group.name),
                  subtitle: Text('${group.members.length}人のメンバー'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => onGroupSelected(group),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
