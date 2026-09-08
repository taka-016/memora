import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/member/update_member_usecase.dart';

final updateMemberUsecaseProvider = Provider<UpdateMemberUsecase>((ref) {
  return UpdateMemberUsecase(ref.watch(memberRepositoryProvider));
});
