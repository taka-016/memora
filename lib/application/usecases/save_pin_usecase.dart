import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../infrastructure/repositories/pin_repository_impl.dart';

class SavePinUseCase {
  final PinRepositoryImpl pinRepository;
  SavePinUseCase(this.pinRepository);

  Future<void> execute(LatLng position) async {
    await pinRepository.savePin(position);
  }
}
