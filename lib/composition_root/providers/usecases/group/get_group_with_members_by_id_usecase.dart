import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/application/usecases/group/get_group_with_members_by_id_usecase.dart';

final getGroupWithMembersByIdUsecaseProvider =
    Provider<GetGroupWithMembersByIdUsecase>((ref) {
      return GetGroupWithMembersByIdUsecase(
        ref.watch(groupQueryServiceProvider),
      );
    });
