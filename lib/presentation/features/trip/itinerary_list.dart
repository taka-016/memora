import 'package:flutter/material.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';

class ItineraryList extends StatelessWidget {
  const ItineraryList({
    super.key,
    required this.items,
    required this.subtitleBuilder,
    required this.onTapItem,
    required this.onDeleteItem,
  });

  final List<ItineraryItemDto> items;
  final List<String> Function(ItineraryItemDto item) subtitleBuilder;
  final ValueChanged<ItineraryItemDto> onTapItem;
  final ValueChanged<ItineraryItemDto> onDeleteItem;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const Key('itinerary_list'),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final subtitleParts = subtitleBuilder(item);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: ListTile(
            key: Key('itineraryListItem_${item.id}'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
            title: Text(item.name),
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
      },
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
