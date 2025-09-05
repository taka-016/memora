import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/entities/group_with_members.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/application/managers/auth_manager.dart';
import 'package:memora/application/controllers/navigation_controller.dart';
import 'package:memora/application/controllers/group_timeline_navigation_controller.dart';
import 'package:memora/presentation/features/timeline/group_list.dart';
import 'package:memora/infrastructure/factories/map_view_factory.dart';

import 'package:memora/presentation/features/group/group_management.dart';
import 'package:memora/presentation/features/member/member_management.dart';
import 'package:memora/presentation/features/setting/settings.dart';
import 'package:memora/presentation/shared/headers/user_drawer_header.dart';
import 'package:memora/presentation/features/account_setting/account_settings.dart';
import 'package:memora/presentation/features/trip/trip_management.dart';
import 'package:memora/application/usecases/get_current_member_usecase.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/value_objects/auth_state.dart';

class TopPage extends StatefulWidget {
  final GetGroupsWithMembersUsecase getGroupsWithMembersUsecase;
  final bool isTestEnvironment;
  final GetCurrentMemberUseCase? getCurrentMemberUseCase;

  const TopPage({
    super.key,
    required this.getGroupsWithMembersUsecase,
    this.isTestEnvironment = false,
    this.getCurrentMemberUseCase,
  });

  @override
  State<TopPage> createState() => _TopPageState();
}

class _TopPageState extends State<TopPage> {
  GetCurrentMemberUseCase? _getCurrentMemberUseCase;
  Member? _currentMember;

  @override
  void initState() {
    super.initState();
    _initializeGetCurrentMemberUseCase();
  }

  void _initializeGetCurrentMemberUseCase() async {
    _getCurrentMemberUseCase = widget.getCurrentMemberUseCase;
    if (_getCurrentMemberUseCase != null) {
      await _loadCurrentMember();
    }
  }

  Future<void> _loadCurrentMember() async {
    try {
      final member = await _getCurrentMemberUseCase!.execute();
      if (mounted) {
        setState(() {
          _currentMember = member;
        });
      }
    } catch (e) {
      // エラー時はnullのまま
    }
  }

  void _onNavigationItemSelected(NavigationItem item, WidgetRef ref) {
    ref.read(navigationControllerProvider.notifier).selectItem(item);
    if (item != NavigationItem.groupTimeline) {
      ref
          .read(groupTimelineNavigationControllerProvider.notifier)
          .resetToGroupList();
    }
    Navigator.of(context).pop();
  }

  void _onGroupSelected(GroupWithMembers groupWithMembers, WidgetRef ref) {
    ref
        .read(groupTimelineNavigationControllerProvider.notifier)
        .showGroupTimeline(groupWithMembers);
  }

  Widget _buildGroupTimelineStack(WidgetRef ref) {
    if (_currentMember == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final timelineState = ref.watch(groupTimelineNavigationControllerProvider);

    return IndexedStack(
      index: ref
          .read(groupTimelineNavigationControllerProvider.notifier)
          .getStackIndex(),
      children: [
        GroupList(
          getGroupsWithMembersUsecase: widget.getGroupsWithMembersUsecase,
          member: _currentMember!,
          onGroupSelected: (group) => _onGroupSelected(group, ref),
        ),
        widget.isTestEnvironment
            ? _buildTestGroupTimeline(ref)
            : timelineState.groupTimelineInstance ?? Container(),
        timelineState.selectedGroupId != null &&
                timelineState.selectedYear != null
            ? TripManagement(
                groupId: timelineState.selectedGroupId!,
                year: timelineState.selectedYear!,
                onBackPressed: () => ref
                    .read(groupTimelineNavigationControllerProvider.notifier)
                    .backFromTripManagement(),
              )
            : Container(),
      ],
    );
  }

  Widget _buildTestGroupTimeline(WidgetRef ref) {
    return Container(
      key: const Key('group_timeline'),
      child: Column(
        children: [
          AppBar(
            leading: IconButton(
              key: const Key('back_button'),
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                ref
                    .read(groupTimelineNavigationControllerProvider.notifier)
                    .showGroupList();
              },
            ),
            title: const Text('テストグループ'),
          ),
          Expanded(
            child: _buildTestPlaceholder(
              key: 'group_timeline_content',
              icon: Icons.timeline,
              title: 'グループ年表テスト',
              subtitle: 'テスト環境',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(WidgetRef ref) {
    final selectedItem = ref.watch(navigationControllerProvider).selectedItem;

    switch (selectedItem) {
      case NavigationItem.groupTimeline:
        return _buildGroupTimelineStack(ref);
      case NavigationItem.mapDisplay:
        return widget.isTestEnvironment
            ? MapViewFactory.create(
                MapViewType.placeholder,
              ).createMapView(pins: [])
            : MapViewFactory.create(MapViewType.google).createMapView(pins: []);
      case NavigationItem.groupManagement:
        if (_currentMember == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return widget.isTestEnvironment
            ? _buildTestPlaceholder(
                key: 'group_settings',
                icon: Icons.group_work,
                title: 'グループ管理',
                subtitle: 'グループ管理画面',
              )
            : GroupManagement(member: _currentMember!);
      case NavigationItem.memberManagement:
        if (_currentMember == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return widget.isTestEnvironment
            ? _buildTestPlaceholder(
                key: 'member_settings',
                icon: Icons.people,
                title: 'メンバー管理',
                subtitle: 'メンバー管理画面',
              )
            : MemberManagement(member: _currentMember!);
      case NavigationItem.settings:
        return const Settings();
      case NavigationItem.accountSettings:
        return const AccountSettings();
    }
  }

  Widget _buildTestPlaceholder({
    required String key,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      key: Key(key),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 100, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return Scaffold(
          appBar: _buildAppBar(),
          drawer: _buildDrawer(context, ref),
          body: _buildBody(ref),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(title: const Text('memora'), leading: _buildMenuButton());
  }

  Widget _buildMenuButton() {
    return Builder(
      builder: (context) => IconButton(
        key: const Key('hamburger_menu'),
        icon: const Icon(Icons.menu),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context),
          ..._buildDrawerItems(ref),
          const Divider(),
          _buildLogoutItem(),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authManagerProvider);
        if (authState.status == AuthStatus.authenticated) {
          return UserDrawerHeader(email: authState.user!.loginId);
        } else {
          return _buildDefaultHeader(context);
        }
      },
    );
  }

  Widget _buildDefaultHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
      child: Text(
        'memora',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 24,
        ),
      ),
    );
  }

  List<Widget> _buildDrawerItems(WidgetRef ref) {
    return [
      _buildDrawerItem(
        Icons.timeline,
        'グループ年表',
        NavigationItem.groupTimeline,
        ref,
      ),
      _buildDrawerItem(Icons.map, '地図表示', NavigationItem.mapDisplay, ref),
      _buildDrawerItem(
        Icons.people,
        'メンバー管理',
        NavigationItem.memberManagement,
        ref,
      ),
      _buildDrawerItem(
        Icons.group_work,
        'グループ管理',
        NavigationItem.groupManagement,
        ref,
      ),
      _buildDrawerItem(Icons.settings, '設定', NavigationItem.settings, ref),
      _buildDrawerItem(
        Icons.account_circle,
        'アカウント設定',
        NavigationItem.accountSettings,
        ref,
      ),
    ];
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    NavigationItem item,
    WidgetRef ref,
  ) {
    final selectedItem = ref.watch(navigationControllerProvider).selectedItem;

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selectedItem == item,
      onTap: () => _onNavigationItemSelected(item, ref),
    );
  }

  Widget _buildLogoutItem() {
    return Consumer(
      builder: (context, ref, child) => ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('ログアウト'),
        onTap: () {
          ref.read(authManagerProvider.notifier).logout();
        },
      ),
    );
  }
}
