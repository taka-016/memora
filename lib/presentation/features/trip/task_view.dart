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

    void notifyChange(List<TaskDto> updated) {
      final normalized = _normalizeOrder(updated);
      tasksState.value = normalized;
      onChanged(normalized);
    }

    bool hasChildren(String taskId) {
      return tasksState.value.any((task) => task.parentTaskId == taskId);
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
      final parentCount = tasksState.value
          .where((task) => task.parentTaskId == null)
          .length;
      final updated = [
        ...tasksState.value,
        TaskDto(
          id: uuid,
          tripId: '',
          orderIndex: parentCount,
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

    Widget buildTaskTile(TaskDto task) {
      final isParent = hasChildren(task.id);
      final isCollapsed = collapsedParents.value.contains(task.id);
      final shouldHide =
          task.parentTaskId != null &&
          collapsedParents.value.contains(task.parentTaskId);
      if (shouldHide) {
        return const SizedBox.shrink();
      }

      final assigned = memberName(task.assignedMemberId);
      final hasParent = task.parentTaskId != null;
      final dueDateLabel = task.dueDate != null
          ? '${task.dueDate!.year}/${task.dueDate!.month.toString().padLeft(2, '0')}/${task.dueDate!.day.toString().padLeft(2, '0')}'
          : null;
      final subtitleParts = <String>[];
      if (assigned != null && assigned.isNotEmpty) {
        subtitleParts.add('担当: $assigned');
      }
      if (dueDateLabel != null) {
        subtitleParts.add('締切: $dueDateLabel');
      }
      if (task.memo != null && task.memo!.isNotEmpty) {
        subtitleParts.add(task.memo!);
      }

      return Card(
        margin: EdgeInsets.fromLTRB(hasParent ? 32 : 4, 4, 4, 4),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (value) => toggleCompletion(task, value),
          ),
          title: Row(
            children: [
              if (isParent)
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
          subtitle: subtitleParts.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: subtitleParts
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
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteTask(task),
              ),
              ReorderableDragStartListener(
                index: tasksState.value.indexWhere((t) => t.id == task.id),
                child: const Icon(Icons.drag_handle),
              ),
            ],
          ),
          onTap: () => showEditBottomSheet(task),
        ),
      );
    }

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
            buildDefaultDragHandles: false,
            itemCount: tasksState.value.length,
            onReorder: (oldIndex, newIndex) {
              final moving = tasksState.value[oldIndex];
              if (moving.parentTaskId == null) {
                final updated = _reorderParentGroup(
                  tasksState.value,
                  oldIndex,
                  newIndex,
                );
                if (updated != null) {
                  notifyChange(updated);
                }
                return;
              }

              final updated = _reorderChildTask(
                tasksState.value,
                oldIndex,
                newIndex,
              );
              if (updated != null) {
                notifyChange(updated);
              }
            },
            itemBuilder: (context, index) {
              final task = tasksState.value[index];
              return KeyedSubtree(
                key: Key('task_item_${task.id}'),
                child: buildTaskTile(task),
              );
            },
          ),
        ),
      ],
    );
  }
}

List<TaskDto> _normalizeOrder(List<TaskDto> tasks) {
  final idSet = tasks.map((task) => task.id).toSet();
  final parents = <TaskDto>[];
  final childrenMap = <String, List<TaskDto>>{};

  for (final task in tasks) {
    final parentId = task.parentTaskId;
    if (parentId != null && idSet.contains(parentId)) {
      childrenMap.putIfAbsent(parentId, () => []).add(task);
    } else {
      parents.add(task.copyWith(parentTaskId: null));
    }
  }

  final normalized = <TaskDto>[];
  for (var i = 0; i < parents.length; i++) {
    final parent = parents[i].copyWith(orderIndex: i, parentTaskId: null);
    normalized.add(parent);
    final children = childrenMap[parent.id] ?? [];
    for (var j = 0; j < children.length; j++) {
      normalized.add(
        children[j].copyWith(parentTaskId: parent.id, orderIndex: j),
      );
    }
  }

  return normalized;
}

List<TaskDto>? _reorderParentGroup(
  List<TaskDto> tasks,
  int oldIndex,
  int newIndex,
) {
  final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
  if (oldIndex < 0 || oldIndex >= tasks.length) {
    return null;
  }
  if (adjustedNewIndex < 0 || adjustedNewIndex > tasks.length) {
    return null;
  }

  final moving = tasks[oldIndex];
  if (moving.parentTaskId != null) {
    return null;
  }

  final listWithoutParent = List<TaskDto>.from(tasks)..removeAt(oldIndex);
  final parents = tasks.where((task) => task.parentTaskId == null).toList();
  final parentsExcludingDragged = parents
      .where((parent) => parent.id != moving.id)
      .toList();

  String? targetRootParentId;
  if (adjustedNewIndex >= listWithoutParent.length) {
    targetRootParentId = null;
  } else {
    final targetTask = listWithoutParent[adjustedNewIndex];
    targetRootParentId = targetTask.parentTaskId ?? targetTask.id;
    if (targetRootParentId == moving.id) {
      return null;
    }
  }

  final insertIndex = targetRootParentId == null
      ? parentsExcludingDragged.length
      : parentsExcludingDragged.indexWhere(
          (parent) => parent.id == targetRootParentId,
        );
  final normalizedInsertIndex = insertIndex < 0
      ? parentsExcludingDragged.length
      : insertIndex;

  final reorderedParents = List<TaskDto>.from(parentsExcludingDragged)
    ..insert(normalizedInsertIndex, moving);
  final childrenMap = _collectChildren(tasks);
  return _mergeParentsAndChildren(reorderedParents, childrenMap);
}

List<TaskDto>? _reorderChildTask(
  List<TaskDto> tasks,
  int oldIndex,
  int newIndex,
) {
  final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
  if (oldIndex < 0 || oldIndex >= tasks.length) {
    return null;
  }
  if (adjustedNewIndex < 0 || adjustedNewIndex > tasks.length) {
    return null;
  }

  final moving = tasks[oldIndex];
  final parentId = moving.parentTaskId;
  if (parentId == null) {
    return null;
  }

  final listWithoutChild = List<TaskDto>.from(tasks)..removeAt(oldIndex);
  final parentPosition = listWithoutChild.indexWhere(
    (task) => task.id == parentId,
  );
  if (parentPosition == -1) {
    return null;
  }
  final siblingCount = listWithoutChild
      .where((task) => task.parentTaskId == parentId)
      .length;
  final start = parentPosition + 1;
  final end = start + siblingCount;
  if (adjustedNewIndex < start || adjustedNewIndex > end) {
    return null;
  }

  final siblings = tasks
      .where((task) => task.parentTaskId == parentId)
      .toList();
  final oldSiblingIndex = siblings.indexWhere((task) => task.id == moving.id);
  if (oldSiblingIndex == -1) {
    return null;
  }

  final newSiblingIndex = adjustedNewIndex - start;
  if (newSiblingIndex == oldSiblingIndex) {
    return null;
  }

  final reorderedSiblings = List<TaskDto>.from(siblings)
    ..removeAt(oldSiblingIndex)
    ..insert(newSiblingIndex, moving);
  final parents = tasks.where((task) => task.parentTaskId == null).toList();
  final childrenMap = _collectChildren(tasks);
  childrenMap[parentId] = reorderedSiblings;
  return _mergeParentsAndChildren(parents, childrenMap);
}

Map<String, List<TaskDto>> _collectChildren(List<TaskDto> tasks) {
  final childrenMap = <String, List<TaskDto>>{};
  for (final task in tasks) {
    final parentId = task.parentTaskId;
    if (parentId == null) {
      continue;
    }
    childrenMap.putIfAbsent(parentId, () => []).add(task);
  }
  return childrenMap;
}

List<TaskDto> _mergeParentsAndChildren(
  List<TaskDto> parents,
  Map<String, List<TaskDto>> childrenMap,
) {
  final merged = <TaskDto>[];
  for (final parent in parents) {
    merged.add(parent);
    merged.addAll(childrenMap[parent.id] ?? []);
  }
  return merged;
}
