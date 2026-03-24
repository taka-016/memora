import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/usecases/trip/get_tasks_by_trip_id_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/features/trip/task_edit_bottom_sheet.dart';
import 'package:memora/presentation/features/trip/task_list.dart';
import 'package:memora/presentation/features/trip/task_list_helpers.dart';
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
          orderIndex: parentTasks(tasksState.value).length,
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
                    errorMessage.value = null;
                    try {
                      final tasks = await ref
                          .read(getTasksByTripIdUsecaseProvider)
                          .execute(copiedId);
                      if (!context.mounted) {
                        return;
                      }
                      notifyChange(_regenerateTasksForPaste(tasks, tripId));
                    } catch (e, stackTrace) {
                      logger.e(
                        'TaskView.pasteTasks: ${e.toString()}',
                        error: e,
                        stackTrace: stackTrace,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      errorMessage.value = 'タスクの取得に失敗しました: $e';
                    }
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
          child: TaskList(
            tasks: tasksState.value,
            collapsedParentIds: collapsedParents.value,
            subtitleBuilder: subtitleParts,
            onToggleCompletion: toggleCompletion,
            onToggleCollapse: toggleCollapse,
            onTapTask: (task) => showEditBottomSheet(task),
            onDeleteTask: deleteTask,
            onReorderParents: (oldIndex, newIndex) {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final parents = parentTasks(tasksState.value);
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
                merged.addAll(childrenOfParent(tasksState.value, parent.id));
              }
              notifyChange(merged);
            },
            onReorderChildren: (parentTask, oldIndex, newIndex) {
              final children = childrenOfParent(
                tasksState.value,
                parentTask.id,
              );
              final normalizedChildren = reorderChildren(
                children,
                oldIndex,
                newIndex,
              );
              notifyChange([
                ...tasksState.value.where(
                  (task) => task.parentTaskId != parentTask.id,
                ),
                ...normalizedChildren,
              ]);
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
