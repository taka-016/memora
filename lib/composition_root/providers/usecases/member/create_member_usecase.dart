import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/mappers/member/member_mapper.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/member/create_member_usecase.dart';

final createMemberUsecaseProvider = Provider<CreateMemberUsecase>((ref) {
  return CreateMemberUsecase(ref.watch(memberRepositoryProvider));
});
