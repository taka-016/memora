import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';

final getGroupsWithMembersUsecaseProvider =
    Provider<GetGroupsWithMembersUsecase>((ref) {
      return GetGroupsWithMembersUsecase(ref.watch(groupQueryServiceProvider));
    });
