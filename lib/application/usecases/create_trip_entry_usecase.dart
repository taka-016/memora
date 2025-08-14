import '../../domain/entities/trip_entry.dart';
import '../../domain/entities/pin.dart';
import '../../domain/repositories/trip_entry_repository.dart';
import '../../domain/repositories/pin_repository.dart';

class CreateTripEntryUsecase {
  final TripEntryRepository _tripEntryRepository;
  final PinRepository _pinRepository;

  CreateTripEntryUsecase(this._tripEntryRepository, this._pinRepository);

  Future<String> execute(TripEntry tripEntry, List<Pin> pins) async {
    // TripEntryを保存してIDを取得
    final tripId = await _tripEntryRepository.saveTripEntry(tripEntry);

    // pinsが存在する場合、生成されたtripIdを設定して保存
    for (final pin in pins) {
      final pinWithTripId = pin.copyWith(tripId: tripId);
      await _pinRepository.savePinWithTrip(pinWithTripId);
    }

    return tripId;
  }
}
