import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/itinerary_item_query_service.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/infrastructure/factories/android_widget_cache_storage_factory.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/presentation/features/setting/settings.dart';
import 'package:memora/presentation/notifiers/current_member_notifier.dart';

import '../../../../helpers/fake_current_member_notifier.dart';

void main() {
  group('Settings', () {
    testWidgets('Androidウィジェットの表示対象グループを選択すると画面に即時反映される', (
      tester,
    ) async {
      final storage = _FakeAndroidWidgetCacheStorage(targetGroupId: 'group-a');

      await tester.pumpWidget(
        _buildTestApp(
          storage: storage,
          groups: const [
            GroupDto(id: 'group-a', ownerId: 'owner', name: 'グループA', members: []),
            GroupDto(id: 'group-b', ownerId: 'owner', name: 'グループB', members: []),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(_radioIconFor(tester, 'グループA').icon, Icons.radio_button_checked);
      expect(
        _radioIconFor(tester, 'グループB').icon,
        Icons.radio_button_unchecked,
      );

      await tester.tap(find.text('グループB'));
      await tester.pumpAndSettle();

      expect(
        _radioIconFor(tester, 'グループA').icon,
        Icons.radio_button_unchecked,
      );
      expect(_radioIconFor(tester, 'グループB').icon, Icons.radio_button_checked);
      expect(storage.targetGroupId, 'group-b');
    });

    testWidgets('Androidウィジェットの表示対象グループを解除すると画面に即時反映される', (
      tester,
    ) async {
      final storage = _FakeAndroidWidgetCacheStorage(targetGroupId: 'group-a');

      await tester.pumpWidget(
        _buildTestApp(
          storage: storage,
          groups: const [
            GroupDto(id: 'group-a', ownerId: 'owner', name: 'グループA', members: []),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(_radioIconFor(tester, 'グループA').icon, Icons.radio_button_checked);
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNotNull,
      );

      await tester.tap(find.text('表示対象を解除'));
      await tester.pumpAndSettle();

      expect(
        _radioIconFor(tester, 'グループA').icon,
        Icons.radio_button_unchecked,
      );
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );
      expect(storage.targetGroupId, isNull);
    });
  });
}

Widget _buildTestApp({
  required _FakeAndroidWidgetCacheStorage storage,
  required List<GroupDto> groups,
}) {
  const member = MemberDto(id: 'member-1', displayName: '太郎');

  return ProviderScope(
    overrides: [
      currentMemberNotifierProvider.overrideWith(
        () => FakeCurrentMemberNotifier.loaded(member),
      ),
      androidWidgetCacheStorageProvider.overrideWithValue(storage),
      groupQueryServiceProvider.overrideWithValue(_FakeGroupQueryService(groups)),
      tripEntryQueryServiceProvider.overrideWithValue(
        _FakeTripEntryQueryService(),
      ),
      itineraryItemQueryServiceProvider.overrideWithValue(
        _FakeItineraryItemQueryService(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: Settings())),
  );
}

Icon _radioIconFor(WidgetTester tester, String groupName) {
  final tile = tester.widget<ListTile>(find.widgetWithText(ListTile, groupName));
  return tile.leading! as Icon;
}

class _FakeGroupQueryService implements GroupQueryService {
  const _FakeGroupQueryService(this.groups);

  final List<GroupDto> groups;

  @override
  Future<List<GroupDto>> getGroupsWithMembersByMemberId(
    String memberId, {
    List<OrderBy>? groupsOrderBy,
    List<OrderBy>? membersOrderBy,
  }) async {
    return groups;
  }

  @override
  Future<List<GroupDto>> getManagedGroupsWithMembersByOwnerId(
    String ownerId, {
    List<OrderBy>? groupsOrderBy,
    List<OrderBy>? membersOrderBy,
  }) async {
    return groups;
  }

  @override
  Future<GroupDto?> getGroupWithMembersById(
    String groupId, {
    List<OrderBy>? membersOrderBy,
  }) async {
    return groups.where((group) => group.id == groupId).firstOrNull;
  }
}

class _FakeTripEntryQueryService implements TripEntryQueryService {
  @override
  Future<TripEntryDto?> getTripEntryById(
    String tripId, {
    List<OrderBy>? pinsOrderBy,
    List<OrderBy>? tasksOrderBy,
    List<OrderBy>? itineraryItemsOrderBy,
  }) async {
    return null;
  }

  @override
  Future<List<TripEntryDto>> getTripEntriesByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    return [];
  }

  @override
  Future<List<TripEntryDto>> getTripEntriesByGroupIdAndYear(
    String groupId,
    int year, {
    List<OrderBy>? orderBy,
  }) async {
    return [];
  }
}

class _FakeItineraryItemQueryService implements ItineraryItemQueryService {
  @override
  Future<List<ItineraryItemDto>> getItineraryItemsByTripId(
    String tripId, {
    List<OrderBy>? orderBy,
  }) async {
    return [];
  }
}

class _FakeAndroidWidgetCacheStorage implements AndroidWidgetCacheStorage {
  _FakeAndroidWidgetCacheStorage({this.targetGroupId});

  String? targetGroupId;
  String? selectedItineraryDateId;
  AndroidWidgetItineraryCacheDto? cache;

  @override
  Future<void> clear() async {
    targetGroupId = null;
    selectedItineraryDateId = null;
    cache = null;
  }

  @override
  Future<void> clearTargetGroupId() async {
    targetGroupId = null;
  }

  @override
  Future<String?> getSelectedItineraryDateId() async {
    return selectedItineraryDateId;
  }

  @override
  Future<String?> getTargetGroupId() async {
    return targetGroupId;
  }

  @override
  Future<AndroidWidgetItineraryCacheDto?> loadItineraryCache() async {
    return cache;
  }

  @override
  Future<void> saveErrorMessage(String? message) async {}

  @override
  Future<void> saveItineraryCache(AndroidWidgetItineraryCacheDto cache) async {
    this.cache = cache;
    selectedItineraryDateId = cache.selectedItineraryDateId;
  }

  @override
  Future<void> saveSelectedItineraryDateId(String? itineraryDateId) async {
    selectedItineraryDateId = itineraryDateId;
  }

  @override
  Future<void> saveTargetGroupId(String groupId) async {
    targetGroupId = groupId;
  }

  @override
  Future<void> updateWidget() async {}
}
