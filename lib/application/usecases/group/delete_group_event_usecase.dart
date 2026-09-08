import 'package:memora/domain/repositories/group/group_event_repository.dart';

class DeleteGroupEventUsecase {
  final GroupEventRepository _groupEventRepository;

  DeleteGroupEventUsecase(this._groupEventRepository);

  Future<void> execute(String groupEventId) async {
    await _groupEventRepository.deleteGroupEvent(groupEventId);
  }
}
