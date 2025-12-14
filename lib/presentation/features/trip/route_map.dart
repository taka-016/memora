part of 'route_info_view.dart';

class RouteMapSection extends StatelessWidget {
  const RouteMapSection({
    super.key,
    required this.isMapVisible,
    required this.isTestEnvironment,
    required this.onToggleVisibility,
    required this.mapBuilder,
  });

  final bool isMapVisible;
  final bool isTestEnvironment;
  final VoidCallback onToggleVisibility;
  final WidgetBuilder mapBuilder;

  @override
  Widget build(BuildContext context) {
    final collapsedHeight = 56.0;
    final expandedHeight = _expandedHeight(context);

    return AnimatedContainer(
      key: const Key('route_info_map_area'),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: isMapVisible ? expandedHeight : collapsedHeight,
      child: Column(
        children: [
          _buildMapToggleButton(),
          if (isMapVisible) Expanded(child: mapBuilder(context)),
        ],
      ),
    );
  }

  double _expandedHeight(BuildContext context) {
    if (isTestEnvironment) {
      return 200.0;
    }
    final height = MediaQuery.of(context).size.height * 0.32;
    return height.clamp(180.0, 320.0);
  }

  Widget _buildMapToggleButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        key: const Key('route_info_map_toggle'),
        onPressed: onToggleVisibility,
        icon: Icon(isMapVisible ? Icons.remove : Icons.add),
        label: Text(isMapVisible ? 'マップ非表示' : 'マップ表示'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
    );
  }
}
