import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/application/usecases/group/get_managed_groups_with_members_usecase.dart';

final getManagedGroupsWithMembersUsecaseProvider =
    Provider<GetManagedGroupsWithMembersUsecase>((ref) {
      return GetManagedGroupsWithMembersUsecase(
        ref.watch(groupQueryServiceProvider),
      );
    });
