import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/application/queries/dvc/dvc_limited_point_query_service.dart';
import 'package:memora/application/queries/dvc/dvc_point_contract_query_service.dart';
import 'package:memora/application/queries/dvc/dvc_point_usage_query_service.dart';
import 'package:memora/application/queries/group/group_event_query_service.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/queries/member/member_event_query_service.dart';
import 'package:memora/application/queries/member/member_invitation_query_service.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/application/queries/trip/location_query_service.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/domain/repositories/group/group_event_repository.dart';
import 'package:memora/domain/repositories/group/group_repository.dart';
import 'package:memora/domain/repositories/dvc/dvc_limited_point_repository.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_contract_repository.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_usage_repository.dart';
import 'package:memora/domain/repositories/member/member_event_repository.dart';
import 'package:memora/domain/repositories/member/member_invitation_repository.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/presentation/notifiers/auth/auth_state.dart';
import 'package:memora/presentation/notifiers/auth/auth_notifier.dart';
import 'package:memora/presentation/notifiers/android_widget/android_widget_launch_notifier.dart';
import 'package:memora/presentation/app/app_router.dart';
import 'package:memora/presentation/app/app_routes.dart';
import 'package:memora/domain/entities/account/user.dart';
import 'package:memora/application/services/android_widget_update_interval_storage.dart';
import 'package:memora/infrastructure/services/shared_preferences_android_widget_update_interval_storage.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/presentation/app/top_page.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';
import 'package:memora/presentation/notifiers/timeline/group_timeline_group_selection_notifier.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_auth_notifier.dart';
import '../../../helpers/fake_current_member_notifier.dart';
import 'top_page_test_support.mocks.dart';

part 'top_page_authentication_tests.dart';
part 'top_page_android_widget_tests.dart';
part 'top_page_navigation_tests.dart';
part 'top_page_back_navigation_tests.dart';

class _MutableAuthNotifier extends FakeAuthNotifier {
  _MutableAuthNotifier(super.initialState);

  void authenticate(UserDto user) {
    state = AuthState.authenticated(user);
  }

  void unauthenticate() {
    state = const AuthState.unauthenticated('');
  }
}

class _PendingAndroidWidgetLaunchNotifier extends AndroidWidgetLaunchNotifier {
  _PendingAndroidWidgetLaunchNotifier(this.tripId);

  final String tripId;

  @override
  AndroidWidgetLaunchState build() {
    return AndroidWidgetLaunchState(pendingTripId: tripId);
  }
}

class _IdleAndroidWidgetLaunchNotifier extends AndroidWidgetLaunchNotifier {
  @override
  AndroidWidgetLaunchState build() {
    return const AndroidWidgetLaunchState();
  }
}

class _MutableAndroidWidgetLaunchNotifier extends AndroidWidgetLaunchNotifier {
  @override
  AndroidWidgetLaunchState build() {
    return const AndroidWidgetLaunchState();
  }

  void receiveTrip(String tripId) {
    cancelPendingLaunch();
    state = AndroidWidgetLaunchState(pendingTripId: tripId);
  }
}

class _InitialUriLoadingAndroidWidgetLaunchNotifier
    extends AndroidWidgetLaunchNotifier {
  @override
  AndroidWidgetLaunchState build() {
    return const AndroidWidgetLaunchState(isInitialUriLoading: true);
  }
}

class _ResolvedAndroidWidgetLaunchNotifier extends AndroidWidgetLaunchNotifier {
  _ResolvedAndroidWidgetLaunchNotifier(this.resolution);

  final AndroidWidgetLaunchResolution resolution;

  @override
  AndroidWidgetLaunchState build() {
    return AndroidWidgetLaunchState(resolution: resolution);
  }
}

class _PendingGroupSelectionNotifier
    extends GroupTimelineGroupSelectionNotifier {
  final loadCompleter = Completer<void>();

  @override
  GroupTimelineGroupSelectionState build() {
    return const GroupTimelineGroupSelectionState(
      status: GroupTimelineGroupSelectionStatus.loading,
    );
  }

  @override
  Future<void> load(MemberDto currentMember) {
    return loadCompleter.future;
  }
}

class _ErrorGroupSelectionNotifier extends GroupTimelineGroupSelectionNotifier {
  _ErrorGroupSelectionNotifier(this.memberId);

  final String memberId;
  bool loadCalled = false;

  @override
  GroupTimelineGroupSelectionState build() {
    return GroupTimelineGroupSelectionState(
      status: GroupTimelineGroupSelectionStatus.error,
      memberId: memberId,
      message: 'エラーが発生しました',
    );
  }

  @override
  Future<void> load(MemberDto currentMember) async {
    loadCalled = true;
  }
}

class _FakeAndroidWidgetCacheStorage implements AndroidWidgetCacheStorage {
  String? targetGroupId;

  @override
  Future<void> clear() async {
    targetGroupId = null;
  }

  @override
  Future<void> clearTargetGroupId() async {
    targetGroupId = null;
  }

  @override
  Future<String?> getSelectedItineraryDateId() async {
    return null;
  }

  @override
  Future<String?> getTargetGroupId() async {
    return targetGroupId;
  }

  @override
  Future<AndroidWidgetItineraryCacheDto?> loadItineraryCache() async {
    return null;
  }

  @override
  Future<void> saveItineraryCache(AndroidWidgetItineraryCacheDto cache) async {}

  @override
  Future<void> saveSelectedItineraryDateId(String? itineraryDateId) async {}

  @override
  Future<void> saveTargetGroupId(String groupId) async {
    targetGroupId = groupId;
  }

  @override
  Future<void> updateWidget() async {}
}

@GenerateMocks([
  GroupQueryService,
  GroupEventQueryService,
  MemberEventQueryService,
  MemberQueryService,
  AuthService,
  AuthNotifier,
  DvcPointContractQueryService,
  DvcLimitedPointQueryService,
  DvcPointUsageQueryService,
  DvcPointContractRepository,
  DvcLimitedPointRepository,
  DvcPointUsageRepository,
  TripEntryQueryService,
  GroupRepository,
  GroupEventRepository,
  TripEntryRepository,
  MemberRepository,
  MemberEventRepository,
  MemberInvitationRepository,
  MemberInvitationQueryService,
  LocationQueryService,
])
class TopPageTestContext {
  final fixedNow = DateTime(2026, 5, 15);

  late MockGroupQueryService mockGroupQueryService;
  late MockGroupEventQueryService mockGroupEventQueryService;
  late MockMemberEventQueryService mockMemberEventQueryService;
  late MockMemberQueryService mockMemberQueryService;
  late MockAuthService mockAuthService;
  late List<GroupDto> groupsWithMembers;
  late MemberDto testMember;
  late MockDvcPointContractQueryService mockDvcPointContractQueryService;
  late MockDvcLimitedPointQueryService mockDvcLimitedPointQueryService;
  late MockDvcPointUsageQueryService mockDvcPointUsageQueryService;
  late MockDvcPointContractRepository mockDvcPointContractRepository;
  late MockDvcLimitedPointRepository mockDvcLimitedPointRepository;
  late MockDvcPointUsageRepository mockDvcPointUsageRepository;
  late MockTripEntryQueryService mockTripEntryQueryService;
  late MockGroupRepository mockGroupRepository;
  late MockGroupEventRepository mockGroupEventRepository;
  late MockTripEntryRepository mockTripEntryRepository;
  late MockMemberRepository mockMemberRepository;
  late MockMemberEventRepository mockMemberEventRepository;
  late MockMemberInvitationRepository mockMemberInvitationRepository;
  late MockMemberInvitationQueryService mockMemberInvitationQueryService;
  late MockLocationQueryService mockLocationQueryService;

  void setUpContext() {
    SharedPreferences.setMockInitialValues({});
    mockGroupQueryService = MockGroupQueryService();
    mockGroupEventQueryService = MockGroupEventQueryService();
    mockMemberEventQueryService = MockMemberEventQueryService();
    mockMemberQueryService = MockMemberQueryService();
    mockAuthService = MockAuthService();
    mockDvcPointContractQueryService = MockDvcPointContractQueryService();
    mockDvcLimitedPointQueryService = MockDvcLimitedPointQueryService();
    mockDvcPointUsageQueryService = MockDvcPointUsageQueryService();
    mockDvcPointContractRepository = MockDvcPointContractRepository();
    mockDvcLimitedPointRepository = MockDvcLimitedPointRepository();
    mockDvcPointUsageRepository = MockDvcPointUsageRepository();
    mockTripEntryQueryService = MockTripEntryQueryService();
    mockGroupRepository = MockGroupRepository();
    mockGroupEventRepository = MockGroupEventRepository();
    mockTripEntryRepository = MockTripEntryRepository();
    mockMemberRepository = MockMemberRepository();
    mockMemberEventRepository = MockMemberEventRepository();
    mockMemberInvitationRepository = MockMemberInvitationRepository();
    mockMemberInvitationQueryService = MockMemberInvitationQueryService();
    mockLocationQueryService = MockLocationQueryService();

    when(
      mockGroupEventQueryService.getGroupEventsByGroupId(
        any,
        orderBy: anyNamed('orderBy'),
      ),
    ).thenAnswer((_) async => []);
    when(
      mockMemberEventQueryService.getMemberEventsByMemberIds(
        any,
        orderBy: anyNamed('orderBy'),
      ),
    ).thenAnswer((_) async => []);
    when(
      mockDvcPointContractQueryService.getDvcPointContractsByGroupId(
        any,
        orderBy: anyNamed('orderBy'),
      ),
    ).thenAnswer((_) async => []);
    when(
      mockDvcLimitedPointQueryService.getDvcLimitedPointsByGroupId(
        any,
        orderBy: anyNamed('orderBy'),
      ),
    ).thenAnswer((_) async => []);
    when(
      mockDvcPointUsageQueryService.getDvcPointUsagesByGroupId(
        any,
        orderBy: anyNamed('orderBy'),
      ),
    ).thenAnswer((_) async => []);
    when(
      mockTripEntryQueryService.getTripEntryById(
        any,
        tasksOrderBy: anyNamed('tasksOrderBy'),
      ),
    ).thenAnswer((_) async => null);
    when(
      mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
        any,
        any,
        orderBy: anyNamed('orderBy'),
      ),
    ).thenAnswer((_) async => []);
    when(
      mockTripEntryQueryService.getTripEntriesByGroupId(
        any,
        orderBy: anyNamed('orderBy'),
      ),
    ).thenAnswer((_) async => []);
    when(mockMemberInvitationQueryService.getByInvitationCode(any))
        .thenAnswer((_) async => null);
    when(mockLocationQueryService.getLocationsByGroupId(any))
        .thenAnswer((_) async => []);
    when(mockMemberInvitationQueryService.getByInviteeId(any))
        .thenAnswer((_) async => null);
    when(mockDvcPointContractRepository.deleteDvcPointContract(any))
        .thenAnswer((_) async {});
    when(mockDvcPointContractRepository.deleteDvcPointContractsByGroupId(any))
        .thenAnswer((_) async {});
    when(mockDvcPointContractRepository.saveDvcPointContract(any))
        .thenAnswer((_) async {});
    when(mockDvcLimitedPointRepository.deleteDvcLimitedPoint(any))
        .thenAnswer((_) async {});
    when(mockDvcLimitedPointRepository.deleteDvcLimitedPointsByGroupId(any))
        .thenAnswer((_) async {});
    when(mockDvcLimitedPointRepository.saveDvcLimitedPoint(any))
        .thenAnswer((_) async {});
    when(mockDvcPointUsageRepository.deleteDvcPointUsage(any))
        .thenAnswer((_) async {});
    when(mockDvcPointUsageRepository.deleteDvcPointUsagesByGroupId(any))
        .thenAnswer((_) async {});
    when(mockDvcPointUsageRepository.saveDvcPointUsage(any))
        .thenAnswer((_) async {});
    when(mockGroupRepository.deleteGroup(any)).thenAnswer((_) async {});
    when(mockGroupRepository.deleteGroupMembersByMemberId(any))
        .thenAnswer((_) async {});
    when(mockGroupRepository.saveGroup(any)).thenAnswer((_) async => 'g1');
    when(mockGroupRepository.updateGroup(any)).thenAnswer((_) async {});
    when(mockGroupEventRepository.deleteGroupEvent(any))
        .thenAnswer((_) async {});
    when(mockGroupEventRepository.deleteGroupEventsByGroupId(any))
        .thenAnswer((_) async {});
    when(mockGroupEventRepository.saveGroupEvent(any))
        .thenAnswer((_) async => 'group-event-1');
    when(mockTripEntryRepository.deleteTripEntriesByGroupId(any))
        .thenAnswer((_) async {});
    when(mockTripEntryRepository.deleteTripEntry(any)).thenAnswer((_) async {});
    when(mockTripEntryRepository.saveTripEntry(any))
        .thenAnswer((_) async => 't1');
    when(mockTripEntryRepository.updateTripEntry(any)).thenAnswer((_) async {});
    when(mockMemberRepository.deleteMember(any)).thenAnswer((_) async {});
    when(mockMemberRepository.saveMember(any)).thenAnswer((_) async {});
    when(mockMemberRepository.updateMember(any)).thenAnswer((_) async {});
    when(mockMemberEventRepository.deleteMemberEvent(any))
        .thenAnswer((_) async {});
    when(mockMemberEventRepository.deleteMemberEventsByMemberId(any))
        .thenAnswer((_) async {});
    when(mockMemberEventRepository.saveMemberEvent(any))
        .thenAnswer((_) async => 'member-event-1');
    when(mockMemberInvitationRepository.deleteMemberInvitation(any))
        .thenAnswer((_) async {});
    when(mockMemberInvitationRepository.saveMemberInvitation(any))
        .thenAnswer((_) async {});
    when(mockMemberInvitationRepository.updateMemberInvitation(any))
        .thenAnswer((_) async {});

    testMember = MemberDto(
      id: 'admin1',
      hiraganaFirstName: 'たろう',
      hiraganaLastName: 'やまだ',
      kanjiFirstName: '太郎',
      kanjiLastName: '山田',
      firstName: 'Taro',
      lastName: 'Yamada',
      displayName: 'タロちゃん',
      type: 'family',
      birthday: DateTime(1990, 1, 1),
      gender: 'male',
    );

    groupsWithMembers = [
      GroupDto(
        id: '1',
        ownerId: 'owner1',
        name: 'グループ1',
        members: [
          GroupMemberDto(
            memberId: 'member1',
            groupId: 'group1',
            displayName: '太郎',
            email: 'taro@example.com',
          ),
          GroupMemberDto(
            memberId: 'member2',
            groupId: 'group2',
            displayName: '花子',
            email: 'hanako@example.com',
          ),
        ],
      ),
      GroupDto(
        id: '2',
        ownerId: 'owner2',
        name: 'グループ2',
        members: [
          GroupMemberDto(
            memberId: 'member3',
            groupId: 'group2',
            displayName: '次郎',
            email: 'jiro@example.com',
          ),
        ],
      ),
    ];

    when(
      mockGroupQueryService.getGroupWithMembersById(
        any,
        membersOrderBy: anyNamed('membersOrderBy'),
      ),
    ).thenAnswer((_) async => groupsWithMembers.first);
    when(
      mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
        any,
        groupsOrderBy: anyNamed('groupsOrderBy'),
        membersOrderBy: anyNamed('membersOrderBy'),
      ),
    ).thenAnswer((_) async => []);
  }

  List<Override> createTopPageTestOverrides({
    MockMemberQueryService? memberQueryService,
    MockAuthService? authService,
    AuthNotifier? authNotifier,
    MemberDto? currentMember,
    List<GroupDto>? availableGroupsWithMembers,
    String initialLocation = '/groups',
    FakeCurrentMemberNotifier? currentMemberNotifier,
    AndroidWidgetLaunchNotifier? androidWidgetLaunchNotifier,
    GroupTimelineGroupSelectionNotifier? groupSelectionNotifier,
  }) {
    final defaultMember = MemberDto(
      id: 'default_member',
      displayName: '表示名',
      kanjiLastName: 'デフォルト',
      kanjiFirstName: 'ユーザー',
    );

    final testMemberQueryService = memberQueryService ?? mockMemberQueryService;
    final testAuthService = authService ?? mockAuthService;
    final resolvedGroupsWithMembers =
        availableGroupsWithMembers ?? groupsWithMembers;

    const testUser = User(
      id: 'test_user_id',
      loginId: 'test@example.com',
      isVerified: true,
    );

    when(testMemberQueryService.getMemberByAccountId(any))
        .thenAnswer((_) async => defaultMember);
    when(testMemberQueryService.getMemberById(any))
        .thenAnswer((_) async => defaultMember);
    when(
      testMemberQueryService.getMembersByOwnerId(
        any,
        orderBy: anyNamed('orderBy'),
      ),
    ).thenAnswer((_) async => []);
    when(testAuthService.getCurrentUser()).thenAnswer((_) async => testUser);
    when(
      mockGroupQueryService.getGroupsWithMembersByMemberId(
        any,
        groupsOrderBy: anyNamed('groupsOrderBy'),
        membersOrderBy: anyNamed('membersOrderBy'),
      ),
    ).thenAnswer((_) async => resolvedGroupsWithMembers);

    final resolvedCurrentMemberNotifier =
        currentMemberNotifier ??
        FakeCurrentMemberNotifier.loaded(currentMember ?? defaultMember);

    return [
      appClockProvider.overrideWithValue(FixedAppClock(fixedNow)),
      authNotifierProvider.overrideWith(
        () => authNotifier ?? FakeAuthNotifier.authenticated(),
      ),
      appInitialLocationProvider.overrideWithValue(initialLocation),
      appTestEnvironmentProvider.overrideWithValue(true),
      currentMemberNotifierProvider.overrideWith(
        () => resolvedCurrentMemberNotifier,
      ),
      if (groupSelectionNotifier != null)
        groupTimelineGroupSelectionNotifierProvider.overrideWith(
          () => groupSelectionNotifier,
        ),
      androidWidgetLaunchNotifierProvider.overrideWith(
        () => androidWidgetLaunchNotifier ?? _IdleAndroidWidgetLaunchNotifier(),
      ),
      androidWidgetCacheStorageProvider.overrideWithValue(
        _FakeAndroidWidgetCacheStorage(),
      ),
      androidWidgetUpdateIntervalStorageProvider.overrideWithValue(
        const SharedPreferencesAndroidWidgetUpdateIntervalStorage(),
      ),
      memberQueryServiceProvider.overrideWithValue(testMemberQueryService),
      authServiceProvider.overrideWithValue(testAuthService),
      groupQueryServiceProvider.overrideWithValue(mockGroupQueryService),
      groupEventQueryServiceProvider.overrideWithValue(
        mockGroupEventQueryService,
      ),
      memberEventQueryServiceProvider.overrideWithValue(
        mockMemberEventQueryService,
      ),
      dvcPointContractQueryServiceProvider.overrideWithValue(
        mockDvcPointContractQueryService,
      ),
      dvcLimitedPointQueryServiceProvider.overrideWithValue(
        mockDvcLimitedPointQueryService,
      ),
      dvcPointUsageQueryServiceProvider.overrideWithValue(
        mockDvcPointUsageQueryService,
      ),
      dvcPointContractRepositoryProvider.overrideWithValue(
        mockDvcPointContractRepository,
      ),
      dvcLimitedPointRepositoryProvider.overrideWithValue(
        mockDvcLimitedPointRepository,
      ),
      dvcPointUsageRepositoryProvider.overrideWithValue(
        mockDvcPointUsageRepository,
      ),
      tripEntryQueryServiceProvider.overrideWithValue(
        mockTripEntryQueryService,
      ),
      mapTripEntryQueryServiceProvider.overrideWithValue(
        mockTripEntryQueryService,
      ),
      locationQueryServiceProvider.overrideWithValue(mockLocationQueryService),
      groupRepositoryProvider.overrideWithValue(mockGroupRepository),
      groupEventRepositoryProvider.overrideWithValue(mockGroupEventRepository),
      tripEntryRepositoryProvider.overrideWithValue(mockTripEntryRepository),
      memberRepositoryProvider.overrideWithValue(mockMemberRepository),
      memberEventRepositoryProvider.overrideWithValue(
        mockMemberEventRepository,
      ),
      memberInvitationRepositoryProvider.overrideWithValue(
        mockMemberInvitationRepository,
      ),
      memberInvitationQueryServiceProvider.overrideWithValue(
        mockMemberInvitationQueryService,
      ),
    ];
  }

  Widget createTestWidget({
    MockMemberQueryService? memberQueryService,
    MockAuthService? authService,
    AuthNotifier? authNotifier,
    MemberDto? currentMember,
    List<GroupDto>? availableGroupsWithMembers,
    String initialLocation = '/groups',
    FakeCurrentMemberNotifier? currentMemberNotifier,
    AndroidWidgetLaunchNotifier? androidWidgetLaunchNotifier,
    GroupTimelineGroupSelectionNotifier? groupSelectionNotifier,
  }) {
    return ProviderScope(
      overrides: createTopPageTestOverrides(
        memberQueryService: memberQueryService,
        authService: authService,
        authNotifier: authNotifier,
        currentMember: currentMember,
        availableGroupsWithMembers: availableGroupsWithMembers,
        initialLocation: initialLocation,
        currentMemberNotifier: currentMemberNotifier,
        androidWidgetLaunchNotifier: androidWidgetLaunchNotifier,
        groupSelectionNotifier: groupSelectionNotifier,
      ),
      child: Consumer(
        builder: (context, ref, _) {
          return MaterialApp.router(
            routerConfig: ref.watch(appRouterConfigProvider),
          );
        },
      ),
    );
  }

  Finder findTimelineHorizontalScrollView() {
    return find
        .descendant(
          of: find.byKey(const Key('group_timeline')),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is SingleChildScrollView &&
                widget.scrollDirection == Axis.horizontal,
          ),
        )
        .first;
  }

  void stubFreshGroupsWithMembers(List<GroupDto> groups) {
    when(
      mockGroupQueryService.getGroupsWithMembersByMemberId(
        any,
        groupsOrderBy: anyNamed('groupsOrderBy'),
        membersOrderBy: anyNamed('membersOrderBy'),
      ),
    ).thenAnswer((_) async => List<GroupDto>.of(groups));
  }
}
