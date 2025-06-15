import 'package:flutter/material.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/domain/services/current_location_service.dart';
import 'package:memora/domain/repositories/pin_repository.dart';
import 'package:memora/presentation/widgets/google_map_widget.dart';

class GoogleMapScreen extends StatelessWidget {
  final List<Pin>? initialPins;
  final CurrentLocationService? locationService;
  final PinRepository? pinRepository;

  const GoogleMapScreen({
    super.key,
    this.initialPins,
    this.locationService,
    this.pinRepository,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Googleマップ')),
      body: GoogleMapWidget(
        initialPins: initialPins,
        locationService: locationService,
        pinRepository: pinRepository,
      ),
    );
  }
}
