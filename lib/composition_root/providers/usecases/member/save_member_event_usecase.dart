import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/member/member_event_dto.dart';
import 'package:memora/application/mappers/member/member_event_mapper.dart';
import 'package:memora/domain/repositories/member/member_event_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/member/save_member_event_usecase.dart';

final saveMemberEventUsecaseProvider = Provider<SaveMemberEventUsecase>((ref) {
  return SaveMemberEventUsecase(ref.watch(memberEventRepositoryProvider));
});
