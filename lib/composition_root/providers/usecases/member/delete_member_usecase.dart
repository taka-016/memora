import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/member/delete_member_usecase.dart';

final deleteMemberUsecaseProvider = Provider<DeleteMemberUsecase>((ref) {
  return DeleteMemberUsecase(
    ref.watch(memberRepositoryProvider),
    ref.watch(groupRepositoryProvider),
    ref.watch(memberEventRepositoryProvider),
  );
});
