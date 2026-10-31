import 'package:flutter/material.dart';

class PlaceholderMapView extends StatelessWidget {
  const PlaceholderMapView({super.key, this.topLeadingOverlay});

  final Widget? topLeadingOverlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('map_view'),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map,
                  size: 100,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                SizedBox(height: 16),
                Text(
                  'マップ表示',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Google Mapウィジェット実装済み',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (topLeadingOverlay != null)
            Positioned(top: 68, left: 16, right: 16, child: topLeadingOverlay!),
        ],
      ),
    );
  }
}
