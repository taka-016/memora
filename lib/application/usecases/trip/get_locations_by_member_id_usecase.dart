import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/location_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getLocationsByMemberIdUsecaseProvider =
    Provider<GetLocationsByMemberIdUsecase>((ref) {
      return GetLocationsByMemberIdUsecase(
        ref.watch(groupQueryServiceProvider),
        ref.watch(locationQueryServiceProvider),
      );
    });

class GetLocationsByMemberIdUsecase {
  GetLocationsByMemberIdUsecase(
    this._groupQueryService,
    this._locationQueryService,
  );

  final GroupQueryService _groupQueryService;
  final LocationQueryService _locationQueryService;

  Future<List<LocationDto>> execute(String memberId) async {
    final groups = await _groupQueryService.getGroupsWithMembersByMemberId(
      memberId,
      groupsOrderBy: [const OrderBy('name', descending: false)],
      membersOrderBy: [const OrderBy('orderIndex', descending: false)],
    );
    final locationsByGroup = await Future.wait(
      groups.map(
        (group) => _locationQueryService.getLocationsByGroupId(group.id),
      ),
    );
    return locationsByGroup.expand((locations) => locations).toList();
  }
}
