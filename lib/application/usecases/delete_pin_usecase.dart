import 'package:memora/domain/repositories/pin_repository.dart';

class DeletePinUseCase {
  final PinRepository pinRepository;
  DeletePinUseCase(this.pinRepository);

  Future<void> execute(String pinId) async {
    await pinRepository.deletePin(pinId);
  }
}
