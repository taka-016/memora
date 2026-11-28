import 'package:material_ui/material_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/presentation/notifiers/map/coordinate_notifier.dart';
import 'package:memora/presentation/shared/inputs/custom_search_bar.dart';
import 'package:memora/presentation/shared/map_views/google_map_view.dart';
import 'package:memora/presentation/shared/map_views/map_view_builder.dart';
import 'package:memora/presentation/shared/sheets/location_detail_bottom_sheet.dart';

class LocationMapView extends ConsumerWidget {
  final List<LocationDto> locations;
  final ValueChanged<Coordinate>? onMapLongTapped;
  final ValueChanged<LocationCandidateDto>? onSearchedLocationSelected;
  final ValueChanged<LocationDto>? onLocationTapped;
  final LocationDto? selectedLocation;
  final LocationDto? focusedLocation;
  final Widget? topLeadingOverlay;
  final bool highlightSelectedLocation;
  final LocationDetailBuilder? locationDetailBuilder;
  final double? locationDetailBottomSheetHeight;
  final DateTime? tripStartDate;
  final bool isReadOnly;

  const LocationMapView({
    super.key,
    required this.locations,
    this.onMapLongTapped,
    this.onSearchedLocationSelected,
    this.onLocationTapped,
    this.selectedLocation,
    this.focusedLocation,
    this.topLeadingOverlay,
    this.highlightSelectedLocation = false,
    this.locationDetailBuilder,
    this.locationDetailBottomSheetHeight,
    this.tripStartDate,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<Coordinate?> getCurrentLocation() async {
      try {
        await ref.read(coordinateProvider.notifier).getCurrentLocation();
        if (!context.mounted) return null;
        final coordinate = ref.read(coordinateProvider).coordinate;
        if (coordinate == null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('現在地が取得できませんでした')));
        }
        return coordinate;
      } catch (e, stack) {
        if (!context.mounted) return null;
        logger.e(
          'LocationMapView.getCurrentLocation: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('現在地取得に失敗: $e')));
        return null;
      }
    }

    return GoogleMapView(
      locations: locations,
      onMapLongTapped: onMapLongTapped,
      onSearchedLocationSelected: onSearchedLocationSelected,
      onLocationTapped: onLocationTapped,
      selectedLocation: selectedLocation,
      focusedLocation: focusedLocation,
      topLeadingOverlay: topLeadingOverlay,
      highlightSelectedLocation: highlightSelectedLocation,
      currentCoordinate: () => ref.read(coordinateProvider).coordinate,
      getCurrentLocation: getCurrentLocation,
      searchBarBuilder: (onSelected) =>
          CustomSearchBar(hintText: '場所を検索', onCandidateSelected: onSelected),
      locationDetailBuilder:
          locationDetailBuilder ??
          (location, onClose, {onPreviousLocation, onNextLocation}) =>
              LocationDetailBottomSheet(
                location: location,
                onClose: onClose,
                height: locationDetailBottomSheetHeight,
                onPreviousLocation: onPreviousLocation,
                onNextLocation: onNextLocation,
              ),
    );
  }
}
