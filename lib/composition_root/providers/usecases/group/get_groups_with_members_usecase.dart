import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';

final getGroupsWithMembersUsecaseProvider =
    Provider<GetGroupsWithMembersUsecase>((ref) {
      return GetGroupsWithMembersUsecase(ref.watch(groupQueryServiceProvider));
    });
