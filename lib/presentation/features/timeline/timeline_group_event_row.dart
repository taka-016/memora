import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/usecases/group/delete_group_event_usecase.dart';
import 'package:memora/application/usecases/group/get_group_events_usecase.dart';
import 'package:memora/application/usecases/group/save_group_event_usecase.dart';
import 'package:memora/presentation/features/group/group_event_edit_modal.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';

class TimelineGroupEventRow extends TimelineRowDefinition {
  const TimelineGroupEventRow({
    required this.groupId,
    required this.initialHeight,
  });

  final String groupId;

  @override
  final double initialHeight;

  @override
  String get fixedColumnLabel => 'イベント';

  @override
  Color get backgroundColor => Colors.lightBlue.shade50;

  @override
  Key yearCellKey(int year) => Key('group_event_cell_$year');

  @override
  Widget buildYearCell(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    return _GroupEventYearCell(
      groupId: groupId,
      year: year,
      refreshKey: rowContext.controller.refreshKey,
      availableHeight: rowContext.rowHeight,
      availableWidth: rowContext.layoutConfig.yearColumnWidth,
    );
  }
}

final _groupEventsByYearProvider = FutureProvider.autoDispose
    .family<Map<int, GroupEventDto>, _GroupEventsQuery>((ref, query) async {
      final events = await ref
          .read(getGroupEventsUsecaseProvider)
          .execute(query.groupId);
      return {for (final event in events) event.year: event};
    });

class _GroupEventYearCell extends HookConsumerWidget {
  const _GroupEventYearCell({
    required this.groupId,
    required this.year,
    required this.refreshKey,
    required this.availableHeight,
    required this.availableWidth,
  });

  final String groupId;
  final int year;
  final int refreshKey;
  final double availableHeight;
  final double availableWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = _GroupEventsQuery(groupId: groupId, refreshKey: refreshKey);
    final eventsByYear = ref.watch(_groupEventsByYearProvider(query));
    final localEvent = useState<GroupEventDto?>(null);
    final loadedEvent = eventsByYear.valueOrNull?[year];

    useEffect(() {
      localEvent.value = loadedEvent;
      return null;
    }, [loadedEvent]);

    final currentEvent = localEvent.value;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final eventAtOpen = localEvent.value;
        await showGroupEventEditModal(
          context: context,
          selectedYear: year,
          initialMemo: eventAtOpen?.memo ?? '',
          onSave: (memo) async {
            if (memo.isEmpty) {
              if (eventAtOpen != null) {
                await ref
                    .read(deleteGroupEventUsecaseProvider)
                    .execute(eventAtOpen.id);
              }
              localEvent.value = null;
            } else {
              final savedEvent = await ref
                  .read(saveGroupEventUsecaseProvider)
                  .execute(
                    GroupEventDto(
                      id: eventAtOpen?.id ?? '',
                      groupId: groupId,
                      year: year,
                      memo: memo,
                    ),
                  );
              localEvent.value = savedEvent;
            }
            ref.invalidate(_groupEventsByYearProvider(query));
          },
        );
      },
      child: currentEvent == null
          ? const SizedBox.expand()
          : GroupEventCell(
              memo: currentEvent.memo,
              availableHeight: availableHeight,
              availableWidth: availableWidth,
            ),
    );
  }
}

class _GroupEventsQuery {
  const _GroupEventsQuery({required this.groupId, required this.refreshKey});

  final String groupId;
  final int refreshKey;

  @override
  bool operator ==(Object other) {
    return other is _GroupEventsQuery &&
        other.groupId == groupId &&
        other.refreshKey == refreshKey;
  }

  @override
  int get hashCode => Object.hash(groupId, refreshKey);
}

class GroupEventCell extends StatelessWidget {
  const GroupEventCell({
    super.key,
    required this.memo,
    required this.availableHeight,
    required this.availableWidth,
  });

  final String memo;
  final double availableHeight;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final trimmedMemo = memo.trim();
    if (trimmedMemo.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxLines = (availableHeight / 20).floor().clamp(1, 20);

    return SizedBox(
      width: availableWidth,
      height: availableHeight,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          trimmedMemo,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
