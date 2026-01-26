import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/usecases/trip/get_tasks_by_trip_id_usecase.dart';
import 'package:memora/presentation/features/trip/task_edit_bottom_sheet.dart';
import 'package:memora/presentation/notifiers/task_copy_notifier.dart';
import 'package:uuid/uuid.dart';

class TaskView extends HookConsumerWidget {
  const TaskView({
    super.key,
    required this.tripId,
    required this.tasks,
    required this.groupMembers,
    required this.onChanged,
    this.onClose,
  });

  final String? tripId;
  final List<TaskDto> tasks;
  final List<GroupMemberDto> groupMembers;
  final ValueChanged<List<TaskDto>> onChanged;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskNameController = useTextEditingController();
    final tasksState = useState<List<TaskDto>>(_normalizeOrder(tasks));
    final collapsedParents = useState<Set<String>>({});
    final errorMessage = useState<String?>(null);
    final copiedTripId = ref.watch(copiedTaskTripIdProvider);
    final canCopy = tripId?.isNotEmpty ?? false;
    final canPaste = copiedTripId?.isNotEmpty ?? false;

    useEffect(() {
      tasksState.value = _normalizeOrder(tasks);
      return null;
    }, [tasks]);

    List<TaskDto> parentTasks() {
      return tasksState.value
          .where((task) => task.parentTaskId == null)
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }

    List<TaskDto> childrenOf(String parentId) {
      return tasksState.value
          .where((task) => task.parentTaskId == parentId)
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }

    void notifyChange(List<TaskDto> updated) {
      final normalized = _normalizeOrder(updated);
      tasksState.value = normalized;
      onChanged(normalized);
    }

    Future<void> showEditBottomSheet(TaskDto task) async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return TaskEditBottomSheet(
            key: const Key('task_edit_bottom_sheet'),
            task: task,
            tasks: tasksState.value,
            groupMembers: groupMembers,
            onSaved: (updatedTask) {
              final updated = List<TaskDto>.from(tasksState.value);
              final index = updated.indexWhere((t) => t.id == updatedTask.id);
              if (index != -1) {
                updated[index] = updatedTask;
                notifyChange(updated);
              }
            },
          );
        },
      );
    }

    Future<bool> confirmPaste() async {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('タスクの置き換え確認'),
            content: const Text('ペーストすると現在のタスクが置き換わります。よろしいですか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                key: const Key('task_paste_confirm_button'),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('置き換える'),
              ),
            ],
          );
        },
      );
      return result ?? false;
    }

    void toggleCompletion(TaskDto task, bool? value) {
      final isCompleted = value ?? false;
      final updated = List<TaskDto>.from(tasksState.value);
      final index = updated.indexWhere((t) => t.id == task.id);
      if (index == -1) {
        return;
      }
      updated[index] = task.copyWith(isCompleted: isCompleted);
      if (task.parentTaskId == null && isCompleted) {
        for (var i = 0; i < updated.length; i++) {
          final candidate = updated[i];
          if (candidate.parentTaskId == task.id && !candidate.isCompleted) {
            updated[i] = candidate.copyWith(isCompleted: true);
          }
        }
      }
      notifyChange(updated);
    }

    void deleteTask(TaskDto task) {
      final updated = tasksState.value.where((t) {
        if (t.id == task.id) {
          return false;
        }
        if (t.parentTaskId == task.id) {
          return false;
        }
        return true;
      }).toList();
      collapsedParents.value = {
        for (final id in collapsedParents.value)
          if (id != task.id) id,
      };
      notifyChange(updated);
    }

    void addTask() {
      final trimmed = taskNameController.text.trim();
      if (trimmed.isEmpty) {
        errorMessage.value = 'タスク名を入力してください';
        return;
      }
      final uuid = const Uuid().v4();
      final updated = [
        ...tasksState.value,
        TaskDto(
          id: uuid,
          tripId: tripId ?? '',
          orderIndex: parentTasks().length,
          name: trimmed,
          isCompleted: false,
        ),
      ];
      taskNameController.clear();
      errorMessage.value = null;
      notifyChange(updated);
    }

    void toggleCollapse(String taskId) {
      final next = Set<String>.from(collapsedParents.value);
      if (next.contains(taskId)) {
        next.remove(taskId);
      } else {
        next.add(taskId);
      }
      collapsedParents.value = next;
    }

    String? memberName(String? memberId) {
      if (memberId == null) {
        return null;
      }
      final matched = groupMembers.where(
        (member) => member.memberId == memberId,
      );
      if (matched.isEmpty) {
        return memberId;
      }
      return matched.first.displayName;
    }

    Widget buildHeader() {
      return Row(
        children: [
          const Text(
            'タスク管理',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            key: const Key('task_copy_button'),
            onPressed: canCopy
                ? () {
                    ref.read(copiedTaskTripIdProvider.notifier).state = tripId;
                  }
                : null,
            icon: const Icon(Icons.copy),
            tooltip: 'タスクをコピー',
          ),
          IconButton(
            key: const Key('task_paste_button'),
            onPressed: canPaste
                ? () async {
                    final copiedId = copiedTripId;
                    if (copiedId == null || copiedId.isEmpty) {
                      return;
                    }
                    final shouldReplace = await confirmPaste();
                    if (!shouldReplace) {
                      return;
                    }
                    final tasks = await ref
                        .read(getTasksByTripIdUsecaseProvider)
                        .execute(copiedId);
                    if (!context.mounted) {
                      return;
                    }
                    notifyChange(_regenerateTasksForPaste(tasks, tripId));
                  }
                : null,
            icon: const Icon(Icons.content_paste),
            tooltip: 'タスクをペースト',
          ),
          IconButton(
            onPressed: () {
              if (onClose != null) {
                onClose!();
              } else {
                Navigator.of(context).maybePop();
              }
            },
            icon: const Icon(Icons.close),
          ),
        ],
      );
    }

    Widget buildErrorBanner() {
      if (errorMessage.value == null) {
        return const SizedBox.shrink();
      }
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          errorMessage.value!,
          style: TextStyle(color: Colors.red.shade700, fontSize: 14),
        ),
      );
    }

    List<String> subtitleParts(TaskDto task) {
      final assigned = memberName(task.assignedMemberId);
      final dueDateLabel = task.dueDate != null
          ? '${task.dueDate!.year}/${task.dueDate!.month.toString().padLeft(2, '0')}/${task.dueDate!.day.toString().padLeft(2, '0')}'
          : null;
      final result = <String>[];
      if (assigned != null && assigned.isNotEmpty) {
        result.add('担当: $assigned');
      }
      if (dueDateLabel != null) {
        result.add('締切: $dueDateLabel');
      }
      if (task.memo != null && task.memo!.isNotEmpty) {
        result.add(task.memo!);
      }
      return result;
    }

    List<TaskDto> reorderChildren(
      List<TaskDto> children,
      int oldIndex,
      int newIndex,
    ) {
      var targetIndex = newIndex;
      if (targetIndex > oldIndex) {
        targetIndex -= 1;
      }
      final updatedChildren = List<TaskDto>.from(children);
      final moved = updatedChildren.removeAt(oldIndex);
      updatedChildren.insert(targetIndex, moved);
      return updatedChildren
          .asMap()
          .entries
          .map((entry) => entry.value.copyWith(orderIndex: entry.key))
          .toList();
    }

    Widget buildChildTile(TaskDto task, int childIndex) {
      final parts = subtitleParts(task);
      return Card(
        key: Key('child_item_${task.id}'),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          minLeadingWidth: 0,
          visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (value) => toggleCompletion(task, value),
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
                onPressed: () => deleteTask(task),
              ),
              ReorderableDragStartListener(
                key: Key('child_drag_${task.id}'),
                index: childIndex,
                child: const Icon(Icons.drag_handle),
              ),
            ],
          ),
          onTap: () => showEditBottomSheet(task),
          horizontalTitleGap: 0,
        ),
      );
    }

    Widget buildParentCard(TaskDto task, int parentIndex) {
      final children = childrenOf(task.id);
      final isCollapsed = collapsedParents.value.contains(task.id);
      final parts = subtitleParts(task);
      return Card(
        key: Key('parent_item_${task.id}'),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: _ParentTaskCard(
          task: task,
          subtitleParts: parts,
          children: children,
          isCollapsed: isCollapsed,
          parentIndex: parentIndex,
          onToggleCompletion: (value) => toggleCompletion(task, value),
          onToggleCollapse: () => toggleCollapse(task.id),
          onTap: () => showEditBottomSheet(task),
          onDelete: children.isEmpty ? () => deleteTask(task) : null,
          onReorderChildren: (oldIndex, newIndex) {
            final normalizedChildren = reorderChildren(
              children,
              oldIndex,
              newIndex,
            );
            notifyChange([
              ...tasksState.value.where((t) => t.parentTaskId != task.id),
              ...normalizedChildren,
            ]);
          },
          buildChildTile: buildChildTile,
        ),
      );
    }

    final parents = parentTasks();

    return Column(
      key: const Key('task_view_root'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildHeader(),
        const SizedBox(height: 12),
        buildErrorBanner(),
        if (errorMessage.value != null) const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('task_name_field'),
                controller: taskNameController,
                decoration: const InputDecoration(
                  labelText: 'タスク名',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: addTask, child: const Text('追加')),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ReorderableListView.builder(
            key: const Key('parent_list'),
            buildDefaultDragHandles: false,
            itemCount: parents.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final updatedParents = List<TaskDto>.from(parents);
              final moved = updatedParents.removeAt(oldIndex);
              updatedParents.insert(newIndex, moved);
              final normalizedParents = updatedParents
                  .asMap()
                  .entries
                  .map((entry) => entry.value.copyWith(orderIndex: entry.key))
                  .toList();
              final merged = <TaskDto>[];
              for (final parent in normalizedParents) {
                merged.add(parent);
                merged.addAll(childrenOf(parent.id));
              }
              notifyChange(merged);
            },
            itemBuilder: (context, index) {
              final task = parents[index];
              return KeyedSubtree(
                key: Key('parent_card_${task.id}'),
                child: buildParentCard(task, index),
              );
            },
          ),
        ),
      ],
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

List<TaskDto> _normalizeOrder(List<TaskDto> tasks) {
  final parents = tasks.where((task) => task.parentTaskId == null).toList()
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  final normalized = <TaskDto>[];

  for (var i = 0; i < parents.length; i++) {
    final parent = parents[i].copyWith(orderIndex: i);
    normalized.add(parent);

    final children =
        tasks.where((task) => task.parentTaskId == parent.id).toList()
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    normalized.addAll(
      children.asMap().entries.map(
        (entry) => entry.value.copyWith(orderIndex: entry.key),
      ),
    );
  }

  final orphanChildren =
      tasks
          .where(
            (task) =>
                task.parentTaskId != null &&
                !parents.any((parent) => parent.id == task.parentTaskId),
          )
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  // 孤立した子タスクを親タスクに変換（parentTaskIdをnullに設定）
  normalized.addAll(
    orphanChildren.asMap().entries.map(
      (entry) => entry.value.copyWith(
        orderIndex: parents.length + entry.key,
        parentTaskId: null,
      ),
    ),
  );

  return normalized;
}

List<TaskDto> _regenerateTasksForPaste(List<TaskDto> tasks, String? tripId) {
  final uuid = const Uuid();
  final idMap = <String, String>{for (final task in tasks) task.id: uuid.v4()};

  return tasks.map((task) {
    final newParentId = task.parentTaskId == null
        ? null
        : idMap[task.parentTaskId];
    return task.copyWith(
      id: idMap[task.id]!,
      tripId: tripId ?? '',
      parentTaskId: newParentId,
    );
  }).toList();
}
