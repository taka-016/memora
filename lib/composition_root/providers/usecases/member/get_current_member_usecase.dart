import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/application/usecases/member/get_current_member_usecase.dart';

final getCurrentMemberUsecaseProvider = Provider<GetCurrentMemberUseCase>((
  ref,
) {
  return GetCurrentMemberUseCase(
    ref.watch(memberQueryServiceProvider),
    ref.watch(authServiceProvider),
  );
});
