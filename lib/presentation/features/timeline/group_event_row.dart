import 'package:material_ui/material_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/presentation/features/group/group_event_edit_modal.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';
import 'package:memora/presentation/notifiers/timeline/timeline_group_events_notifier.dart';

class GroupEventRow extends TimelineRowDefinition {
  const GroupEventRow({required this.groupId, required this.initialHeight});

  final String groupId;

  @override
  final double initialHeight;

  @override
  String get fixedColumnLabel => 'イベント';

  @override
  Color get backgroundColor => Colors.lightBlue.withValues(alpha: .1);

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
      availableHeight: rowContext.rowHeight,
      availableWidth: rowContext.layoutConfig.yearColumnWidth,
    );
  }
}

class _GroupEventYearCell extends ConsumerWidget {
  const _GroupEventYearCell({
    required this.groupId,
    required this.year,
    required this.availableHeight,
    required this.availableWidth,
  });

  final String groupId;
  final int year;
  final double availableHeight;
  final double availableWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = timelineGroupEventsNotifierProvider(groupId);
    final eventsByYear = ref.watch(provider).eventsByYear;
    if (eventsByYear == null) return const SizedBox.expand();
    final currentEvent = eventsByYear[year];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final notifier = ref.read(provider.notifier);
        final eventAtOpen = currentEvent;
        await showGroupEventEditModal(
          context: context,
          selectedYear: year,
          initialMemo: eventAtOpen?.memo ?? '',
          onSave: (memo) =>
              notifier.save(year: year, memo: memo, eventAtOpen: eventAtOpen),
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
