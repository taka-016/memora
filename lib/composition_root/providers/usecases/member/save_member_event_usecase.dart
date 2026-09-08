import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/member/save_member_event_usecase.dart';

final saveMemberEventUsecaseProvider = Provider<SaveMemberEventUsecase>((ref) {
  return SaveMemberEventUsecase(ref.watch(memberEventRepositoryProvider));
});
