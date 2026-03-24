import 'package:flutter/material.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';

class TaskList extends StatelessWidget {
  const TaskList({
    super.key,
    required this.tasks,
    required this.collapsedParentIds,
    required this.subtitleBuilder,
    required this.onToggleCompletion,
    required this.onToggleCollapse,
    required this.onTapTask,
    required this.onDeleteTask,
    required this.onReorderParents,
    required this.onReorderChildren,
  });

  final List<TaskDto> tasks;
  final Set<String> collapsedParentIds;
  final List<String> Function(TaskDto task) subtitleBuilder;
  final void Function(TaskDto task, bool? value) onToggleCompletion;
  final ValueChanged<String> onToggleCollapse;
  final ValueChanged<TaskDto> onTapTask;
  final ValueChanged<TaskDto> onDeleteTask;
  final void Function(int oldIndex, int newIndex) onReorderParents;
  final void Function(TaskDto parentTask, int oldIndex, int newIndex)
  onReorderChildren;

  @override
  Widget build(BuildContext context) {
    final parents = _parentTasks(tasks);

    return ReorderableListView.builder(
      key: const Key('parent_list'),
      buildDefaultDragHandles: false,
      itemCount: parents.length,
      onReorder: onReorderParents,
      itemBuilder: (context, index) {
        final task = parents[index];
        final children = _childrenOf(tasks, task.id);
        final isCollapsed = collapsedParentIds.contains(task.id);

        return KeyedSubtree(
          key: Key('parent_card_${task.id}'),
          child: Card(
            key: Key('parent_item_${task.id}'),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: _ParentTaskCard(
              task: task,
              subtitleParts: subtitleBuilder(task),
              children: children,
              isCollapsed: isCollapsed,
              parentIndex: index,
              onToggleCompletion: (value) => onToggleCompletion(task, value),
              onToggleCollapse: () => onToggleCollapse(task.id),
              onTap: () => onTapTask(task),
              onDelete: children.isEmpty ? () => onDeleteTask(task) : null,
              onReorderChildren: (oldIndex, newIndex) =>
                  onReorderChildren(task, oldIndex, newIndex),
              buildChildTile: (childTask, childIndex) {
                return _buildChildTile(
                  task: childTask,
                  childIndex: childIndex,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildChildTile({required TaskDto task, required int childIndex}) {
    final parts = subtitleBuilder(task);
    return Card(
      key: Key('child_item_${task.id}'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        minLeadingWidth: 0,
        visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (value) => onToggleCompletion(task, value),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        title: Text(
          task.name,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: parts.isNotEmpty ? _TaskSubtitle(parts: parts) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: Key('delete_task_${task.id}'),
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDeleteTask(task),
            ),
            ReorderableDragStartListener(
              key: Key('child_drag_${task.id}'),
              index: childIndex,
              child: const Icon(Icons.drag_handle),
            ),
          ],
        ),
        onTap: () => onTapTask(task),
        horizontalTitleGap: 0,
      ),
    );
  }
}

class _ParentTaskCard extends StatelessWidget {
  const _ParentTaskCard({
    required this.task,
    required this.subtitleParts,
    required this.children,
    required this.isCollapsed,
    required this.parentIndex,
    required this.onToggleCompletion,
    required this.onToggleCollapse,
    required this.onTap,
    required this.onReorderChildren,
    required this.buildChildTile,
    this.onDelete,
  });

  final TaskDto task;
  final List<String> subtitleParts;
  final List<TaskDto> children;
  final bool isCollapsed;
  final int parentIndex;
  final ValueChanged<bool?> onToggleCompletion;
  final VoidCallback onToggleCollapse;
  final VoidCallback onTap;
  final void Function(int oldIndex, int newIndex) onReorderChildren;
  final Widget Function(TaskDto task, int index) buildChildTile;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          _ParentTaskTile(
            task: task,
            subtitleParts: subtitleParts,
            childrenExist: children.isNotEmpty,
            isCollapsed: isCollapsed,
            parentIndex: parentIndex,
            onToggleCompletion: onToggleCompletion,
            onToggleCollapse: onToggleCollapse,
            onTap: onTap,
            onDelete: onDelete,
          ),
          if (children.isNotEmpty && !isCollapsed)
            _ChildTaskList(
              parentId: task.id,
              children: children,
              onReorderChildren: onReorderChildren,
              buildChildTile: buildChildTile,
            ),
        ],
      ),
    );
  }
}

class _ParentTaskTile extends StatelessWidget {
  const _ParentTaskTile({
    required this.task,
    required this.subtitleParts,
    required this.childrenExist,
    required this.isCollapsed,
    required this.parentIndex,
    required this.onToggleCompletion,
    required this.onToggleCollapse,
    required this.onTap,
    this.onDelete,
  });

  final TaskDto task;
  final List<String> subtitleParts;
  final bool childrenExist;
  final bool isCollapsed;
  final int parentIndex;
  final ValueChanged<bool?> onToggleCompletion;
  final VoidCallback onToggleCollapse;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 4, right: 12),
      minLeadingWidth: 0,
      visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Visibility(
            visible: childrenExist,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Transform.scale(
              scale: 1.3,
              child: IconButton(
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                iconSize: 32,
                icon: Icon(isCollapsed ? Icons.expand_more : Icons.expand_less),
                onPressed: onToggleCollapse,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          Checkbox(
            value: task.isCompleted,
            onChanged: onToggleCompletion,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      title: Text(
        task.name,
        style: TextStyle(
          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: subtitleParts.isNotEmpty
          ? _TaskSubtitle(parts: subtitleParts)
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!childrenExist && onDelete != null)
            IconButton(
              key: Key('delete_task_${task.id}'),
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ReorderableDragStartListener(
            key: Key('parent_drag_${task.id}'),
            index: parentIndex,
            child: const Icon(Icons.drag_handle),
          ),
        ],
      ),
      onTap: onTap,
      horizontalTitleGap: 0,
    );
  }
}

class _ChildTaskList extends StatelessWidget {
  const _ChildTaskList({
    required this.parentId,
    required this.children,
    required this.onReorderChildren,
    required this.buildChildTile,
  });

  final String parentId;
  final List<TaskDto> children;
  final void Function(int oldIndex, int newIndex) onReorderChildren;
  final Widget Function(TaskDto task, int index) buildChildTile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 4, top: 4),
      child: DragBoundary(
        child: ReorderableListView.builder(
          key: Key('child_list_$parentId'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          dragBoundaryProvider: DragBoundary.forRectOf,
          itemCount: children.length,
          onReorder: onReorderChildren,
          itemBuilder: (context, index) {
            final child = children[index];
            return KeyedSubtree(
              key: Key('child_key_${child.id}'),
              child: buildChildTile(child, index),
            );
          },
        ),
      ),
    );
  }
}

class _TaskSubtitle extends StatelessWidget {
  const _TaskSubtitle({required this.parts});

  final List<String> parts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: parts
            .map((text) => Text(text, style: const TextStyle(fontSize: 12)))
            .toList(),
      ),
    );
  }
}

List<TaskDto> _parentTasks(List<TaskDto> tasks) {
  return tasks.where((task) => task.parentTaskId == null).toList()
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
}

List<TaskDto> _childrenOf(List<TaskDto> tasks, String parentId) {
  return tasks.where((task) => task.parentTaskId == parentId).toList()
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
}
