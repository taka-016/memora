import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/repositories/group_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final getGroupByIdUsecaseProvider = Provider<GetGroupByIdUsecase>((ref) {
  return GetGroupByIdUsecase(ref.watch(groupRepositoryProvider));
});

class GetGroupByIdUsecase {
  final GroupRepository _groupRepository;

  GetGroupByIdUsecase(this._groupRepository);

  Future<Group?> execute(String id) async {
    return await _groupRepository.getGroupById(id);
  }
}
