import 'package:flutter_verification/domain/entities/pin.dart';
import 'package:flutter_verification/domain/repositories/pin_repository.dart';

class LoadPinsUseCase {
  final PinRepository _pinRepository;

  LoadPinsUseCase(this._pinRepository);

  /// ピンの位置リストを取得して返す
  Future<List<Pin>> execute() async {
    return await _pinRepository.getPins();
  }
}
