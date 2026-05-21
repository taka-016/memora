import 'package:flutter/material.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';

class ItineraryList extends StatelessWidget {
  const ItineraryList({
    super.key,
    required this.items,
    required this.collapsedDateGroupKeys,
    required this.timeLabelBuilder,
    required this.subtitleBuilder,
    required this.onToggleDateGroup,
    required this.onTapItem,
    required this.onDeleteItem,
  });

  final List<ItineraryItemDto> items;
  final Set<String> collapsedDateGroupKeys;
  final String Function(ItineraryItemDto item) timeLabelBuilder;
  final List<String> Function(ItineraryItemDto item) subtitleBuilder;
  final ValueChanged<String> onToggleDateGroup;
  final ValueChanged<ItineraryItemDto> onTapItem;
  final ValueChanged<ItineraryItemDto> onDeleteItem;

  @override
  Widget build(BuildContext context) {
    final groups = itineraryDateGroups(items);

    return ListView.builder(
      key: const Key('itinerary_list'),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final isCollapsed = collapsedDateGroupKeys.contains(group.key);

        return _ItineraryDateGroupSection(
          group: group,
          isCollapsed: isCollapsed,
          timeLabelBuilder: timeLabelBuilder,
          subtitleBuilder: subtitleBuilder,
          onToggle: () => onToggleDateGroup(group.key),
          onTapItem: onTapItem,
          onDeleteItem: onDeleteItem,
        );
      },
    );
  }
}

class ItineraryDateGroup {
  const ItineraryDateGroup({
    required this.key,
    required this.label,
    required this.items,
  });

  final String key;
  final String label;
  final List<ItineraryItemDto> items;
}

List<ItineraryDateGroup> itineraryDateGroups(List<ItineraryItemDto> items) {
  final groups = <ItineraryDateGroup>[];

  for (final item in items) {
    final key = itineraryDateGroupKey(item.startDateTime);
    if (groups.isEmpty || groups.last.key != key) {
      groups.add(
        ItineraryDateGroup(
          key: key,
          label: itineraryDateGroupLabel(item.startDateTime),
          items: [item],
        ),
      );
      continue;
    }

    groups.last.items.add(item);
  }

  return groups;
}

String itineraryDateGroupKey(DateTime? startDateTime) {
  if (startDateTime == null) {
    return 'no_start';
  }
  return [
    startDateTime.year.toString().padLeft(4, '0'),
    startDateTime.month.toString().padLeft(2, '0'),
    startDateTime.day.toString().padLeft(2, '0'),
  ].join('-');
}

String itineraryDateGroupLabel(DateTime? startDateTime) {
  if (startDateTime == null) {
    return '開始日未設定';
  }
  return [
    startDateTime.year.toString().padLeft(4, '0'),
    '/',
    startDateTime.month.toString().padLeft(2, '0'),
    '/',
    startDateTime.day.toString().padLeft(2, '0'),
  ].join();
}

class _ItineraryDateGroupSection extends StatelessWidget {
  const _ItineraryDateGroupSection({
    required this.group,
    required this.isCollapsed,
    required this.timeLabelBuilder,
    required this.subtitleBuilder,
    required this.onToggle,
    required this.onTapItem,
    required this.onDeleteItem,
  });

  final ItineraryDateGroup group;
  final bool isCollapsed;
  final String Function(ItineraryItemDto item) timeLabelBuilder;
  final List<String> Function(ItineraryItemDto item) subtitleBuilder;
  final VoidCallback onToggle;
  final ValueChanged<ItineraryItemDto> onTapItem;
  final ValueChanged<ItineraryItemDto> onDeleteItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: Key('itinerary_date_group_${group.key}'),
      children: [
        _ItineraryDateGroupHeader(
          group: group,
          isCollapsed: isCollapsed,
          onToggle: onToggle,
        ),
        if (!isCollapsed)
          ...group.items.map(
            (item) => _ItineraryItemCard(
              item: item,
              timeLabel: timeLabelBuilder(item),
              subtitleParts: subtitleBuilder(item),
              onTapItem: onTapItem,
              onDeleteItem: onDeleteItem,
            ),
          ),
      ],
    );
  }
}

class _ItineraryDateGroupHeader extends StatelessWidget {
  const _ItineraryDateGroupHeader({
    required this.group,
    required this.isCollapsed,
    required this.onToggle,
  });

  final ItineraryDateGroup group;
  final bool isCollapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          InkWell(
            key: Key('toggle_itinerary_date_group_${group.key}'),
            onTap: onToggle,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isCollapsed ? Icons.expand_more : Icons.expand_less),
                  const SizedBox(width: 4),
                  Text(
                    group.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _ItineraryItemCard extends StatelessWidget {
  const _ItineraryItemCard({
    required this.item,
    required this.timeLabel,
    required this.subtitleParts,
    required this.onTapItem,
    required this.onDeleteItem,
  });

  final ItineraryItemDto item;
  final String timeLabel;
  final List<String> subtitleParts;
  final ValueChanged<ItineraryItemDto> onTapItem;
  final ValueChanged<ItineraryItemDto> onDeleteItem;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: ListTile(
        key: Key('itineraryListItem_${item.id}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
        title: _ItineraryItemTitle(timeLabel: timeLabel, name: item.name),
        subtitle: subtitleParts.isEmpty
            ? null
            : _ItinerarySubtitle(parts: subtitleParts),
        trailing: IconButton(
          key: Key('delete_itinerary_${item.id}'),
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => onDeleteItem(item),
        ),
        onTap: () => onTapItem(item),
      ),
    );
  }
}

class _ItineraryItemTitle extends StatelessWidget {
  const _ItineraryItemTitle({required this.timeLabel, required this.name});

  final String timeLabel;
  final String name;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (timeLabel.isNotEmpty) Text(timeLabel, style: textStyle),
        Text(name, style: textStyle),
      ],
    );
  }
}

class _ItinerarySubtitle extends StatelessWidget {
  const _ItinerarySubtitle({required this.parts});

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
