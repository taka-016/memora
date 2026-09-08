import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';
import 'package:memora/domain/repositories/group/group_repository.dart';
import 'package:memora/domain/repositories/member/member_event_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/member/delete_member_usecase.dart';

final deleteMemberUsecaseProvider = Provider<DeleteMemberUsecase>((ref) {
  return DeleteMemberUsecase(
    ref.watch(memberRepositoryProvider),
    ref.watch(groupRepositoryProvider),
    ref.watch(memberEventRepositoryProvider),
  );
});
