import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/repositories/group/group_event_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final deleteGroupEventUsecaseProvider = Provider<DeleteGroupEventUsecase>((
  ref,
) {
  return DeleteGroupEventUsecase(ref.watch(groupEventRepositoryProvider));
});

class DeleteGroupEventUsecase {
  final GroupEventRepository _groupEventRepository;

  DeleteGroupEventUsecase(this._groupEventRepository);

  Future<void> execute(String groupEventId) async {
    await _groupEventRepository.deleteGroupEvent(groupEventId);
  }
}
