import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/application/managers/auth_manager.dart';
import 'package:memora/presentation/features/timeline/group_list.dart';
import 'package:memora/presentation/features/timeline/group_timeline.dart';
import 'package:memora/infrastructure/factories/map_view_factory.dart';

import 'package:memora/presentation/features/group/group_management.dart';
import 'package:memora/presentation/features/member/member_management.dart';
import 'package:memora/presentation/features/setting/settings.dart';
import 'package:memora/presentation/shared/headers/user_drawer_header.dart';
import 'package:memora/presentation/features/account_setting/account_settings.dart';
import 'package:memora/presentation/features/trip/trip_management.dart';
import 'package:memora/application/usecases/get_current_member_usecase.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/value-objects/auth_state.dart';

enum NavigationItem {
  groupTimeline, // グループ年表
  mapDisplay, // マップ表示
  groupManagement, // グループ設定
  memberManagement, // メンバー設定
  settings, // 設定
  accountSettings, // アカウント設定
}

enum GroupTimelineScreenState {
  groupList, // グループ一覧を表示
  timeline, // 年表を表示
  tripManagement, // 旅行管理を表示
}

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
  NavigationItem _selectedItem = NavigationItem.groupTimeline;
  GroupTimelineScreenState _groupTimelineState =
      GroupTimelineScreenState.groupList;
  GetCurrentMemberUseCase? _getCurrentMemberUseCase;
  Member? _currentMember;
  String? _selectedGroupId;
  int? _selectedYear;
  GroupTimeline? _groupTimelineInstance;

  // テスト用メソッド
  @visibleForTesting
  GroupTimeline? get groupTimelineInstanceForTest => _groupTimelineInstance;

  @visibleForTesting
  GroupTimelineScreenState get groupTimelineStateForTest => _groupTimelineState;

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

  void _onNavigationItemSelected(NavigationItem item) {
    setState(() {
      _selectedItem = item;
      // グループ年表以外を選択した場合は状態をリセット
      if (item != NavigationItem.groupTimeline) {
        _groupTimelineState = GroupTimelineScreenState.groupList;
        _groupTimelineInstance = null;
      }
    });
    Navigator.of(context).pop();
  }

  void _onGroupSelected(GroupWithMembers groupWithMembers) {
    setState(() {
      _groupTimelineState = GroupTimelineScreenState.timeline;
      // グループ一覧からの遷移は毎回新しいインスタンスを作成
      _groupTimelineInstance = GroupTimeline(
        groupWithMembers: groupWithMembers,
        onBackPressed: () {
          setState(() {
            _groupTimelineState = GroupTimelineScreenState.groupList;
            _groupTimelineInstance = null;
          });
        },
        onTripManagementSelected: _onTripManagementSelected,
      );
    });
  }

  void _onTripManagementSelected(String groupId, int year) {
    setState(() {
      _groupTimelineState = GroupTimelineScreenState.tripManagement;
      _selectedGroupId = groupId;
      _selectedYear = year;
    });
  }

  int _getGroupTimelineIndex() {
    switch (_groupTimelineState) {
      case GroupTimelineScreenState.groupList:
        return 0;
      case GroupTimelineScreenState.timeline:
        return 1;
      case GroupTimelineScreenState.tripManagement:
        return 2;
    }
  }

  Widget _buildGroupTimelineStack() {
    if (_currentMember == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return IndexedStack(
      index: _getGroupTimelineIndex(),
      children: [
        // 0: グループ一覧
        GroupList(
          getGroupsWithMembersUsecase: widget.getGroupsWithMembersUsecase,
          member: _currentMember!,
          onGroupSelected: _onGroupSelected,
        ),
        // 1: グループ年表
        widget.isTestEnvironment
            ? _buildTestGroupTimeline()
            : _groupTimelineInstance ?? Container(),
        // 2: 旅行管理
        _selectedGroupId != null && _selectedYear != null
            ? TripManagement(
                groupId: _selectedGroupId!,
                year: _selectedYear!,
                onBackPressed: () {
                  setState(() {
                    _groupTimelineState = GroupTimelineScreenState.timeline;
                    _selectedGroupId = null;
                    _selectedYear = null;
                  });
                },
              )
            : Container(),
      ],
    );
  }

  Widget _buildTestGroupTimeline() {
    return Container(
      key: const Key('group_timeline'),
      child: Column(
        children: [
          AppBar(
            leading: IconButton(
              key: const Key('back_button'),
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _groupTimelineState = GroupTimelineScreenState.groupList;
                  _groupTimelineInstance = null;
                });
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

  Widget _buildBody() {
    switch (_selectedItem) {
      case NavigationItem.groupTimeline:
        return _buildGroupTimelineStack();
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
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(context),
      body: _buildBody(),
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

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context),
          ..._buildDrawerItems(),
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

  List<Widget> _buildDrawerItems() {
    return [
      _buildDrawerItem(Icons.timeline, 'グループ年表', NavigationItem.groupTimeline),
      _buildDrawerItem(Icons.map, '地図表示', NavigationItem.mapDisplay),
      _buildDrawerItem(Icons.people, 'メンバー管理', NavigationItem.memberManagement),
      _buildDrawerItem(
        Icons.group_work,
        'グループ管理',
        NavigationItem.groupManagement,
      ),
      _buildDrawerItem(Icons.settings, '設定', NavigationItem.settings),
      _buildDrawerItem(
        Icons.account_circle,
        'アカウント設定',
        NavigationItem.accountSettings,
      ),
    ];
  }

  Widget _buildDrawerItem(IconData icon, String title, NavigationItem item) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedItem == item,
      onTap: () => _onNavigationItemSelected(item),
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
