import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/application/usecases/member/get_managed_members_usecase.dart';

final getManagedMembersUsecaseProvider = Provider<GetManagedMembersUsecase>((
  ref,
) {
  return GetManagedMembersUsecase(ref.watch(memberQueryServiceProvider));
});
