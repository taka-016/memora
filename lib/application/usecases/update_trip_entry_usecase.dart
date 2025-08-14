import '../../domain/entities/trip_entry.dart';
import '../../domain/entities/pin.dart';
import '../../domain/repositories/trip_entry_repository.dart';
import '../../domain/repositories/pin_repository.dart';

class UpdateTripEntryUsecase {
  final TripEntryRepository _tripEntryRepository;
  final PinRepository _pinRepository;

  UpdateTripEntryUsecase(this._tripEntryRepository, this._pinRepository);

  Future<void> execute(TripEntry tripEntry, List<Pin> pins) async {
    // TripEntryを更新
    await _tripEntryRepository.updateTripEntry(tripEntry);

    // 既存のpinsを削除（Delete & Insertパターン）
    await _pinRepository.deletePinsByTripId(tripEntry.id);

    // 新しいpinsを保存
    for (final pin in pins) {
      final pinWithTripId = pin.copyWith(tripId: tripEntry.id);
      await _pinRepository.savePinWithTrip(pinWithTripId);
    }
  }
}
