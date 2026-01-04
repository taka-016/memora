import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/presentation/features/trip/task_edit_bottom_sheet.dart';
import 'package:uuid/uuid.dart';

class TaskView extends HookWidget {
  const TaskView({
    super.key,
    required this.tasks,
    required this.groupMembers,
    required this.onChanged,
    this.onClose,
  });

  final List<TaskDto> tasks;
  final List<GroupMemberDto> groupMembers;
  final ValueChanged<List<TaskDto>> onChanged;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final taskNameController = useTextEditingController();
    final tasksState = useState<List<TaskDto>>(_normalizeOrder(tasks));
    final collapsedParents = useState<Set<String>>({});
    final errorMessage = useState<String?>(null);

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

      if (!context.mounted) {
        return;
      }
    }

    void toggleCompletion(TaskDto task, bool? value) {
      final updated = List<TaskDto>.from(tasksState.value);
      final index = updated.indexWhere((t) => t.id == task.id);
      if (index == -1) {
        return;
      }
      updated[index] = task.copyWith(isCompleted: value ?? false);
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
          tripId: '',
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

    Widget buildChildTile(TaskDto task, int childIndex) {
      final parts = subtitleParts(task);
      return Card(
        key: Key('child_item_${task.id}'),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (value) => toggleCompletion(task, value),
          ),
          title: Text(
            task.name,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: parts.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: parts
                        .map(
                          (text) =>
                              Text(text, style: const TextStyle(fontSize: 12)),
                        )
                        .toList(),
                  ),
                )
              : null,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: Checkbox(
                  value: task.isCompleted,
                  onChanged: (value) => toggleCompletion(task, value),
                ),
                title: Row(
                  children: [
                    if (children.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          isCollapsed ? Icons.expand_more : Icons.expand_less,
                        ),
                        onPressed: () => toggleCollapse(task.id),
                        visualDensity: VisualDensity.compact,
                      ),
                    Expanded(
                      child: Text(
                        task.name,
                        style: TextStyle(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: parts.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: parts
                              .map(
                                (text) => Text(
                                  text,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              )
                              .toList(),
                        ),
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (children.isEmpty)
                      IconButton(
                        key: Key('delete_task_${task.id}'),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteTask(task),
                      ),
                    ReorderableDragStartListener(
                      key: Key('parent_drag_${task.id}'),
                      index: parentIndex,
                      child: const Icon(Icons.drag_handle),
                    ),
                  ],
                ),
                onTap: () => showEditBottomSheet(task),
              ),
              if (children.isNotEmpty && !isCollapsed)
                Padding(
                  padding: const EdgeInsets.only(left: 32, right: 4, top: 4),
                  child: ReorderableListView.builder(
                    key: Key('child_list_${task.id}'),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: children.length,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final updatedChildren = List<TaskDto>.from(children);
                      final moved = updatedChildren.removeAt(oldIndex);
                      updatedChildren.insert(newIndex, moved);
                      final normalizedChildren = updatedChildren
                          .asMap()
                          .entries
                          .map(
                            (entry) =>
                                entry.value.copyWith(orderIndex: entry.key),
                          )
                          .toList();
                      notifyChange([
                        ...tasksState.value.where(
                          (t) => t.parentTaskId != task.id,
                        ),
                        ...normalizedChildren,
                      ]);
                    },
                    itemBuilder: (context, index) {
                      final child = children[index];
                      return KeyedSubtree(
                        key: Key('child_key_${child.id}'),
                        child: buildChildTile(child, index),
                      );
                    },
                  ),
                ),
            ],
          ),
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

  normalized.addAll(
    orphanChildren.asMap().entries.map(
      (entry) => entry.value.copyWith(orderIndex: entry.key),
    ),
  );

  return normalized;
}
