import 'package:flutter/material.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/presentation/shared/group_selection/group_selection_list.dart';

class GroupList extends StatelessWidget {
  final void Function(GroupDto)? onGroupSelected;

  const GroupList({super.key, this.onGroupSelected});

  @override
  Widget build(BuildContext context) {
    return GroupSelectionList(
      onGroupSelected: onGroupSelected,
      title: 'グループを選択',
      listKey: const Key('group_list'),
    );
  }
}
