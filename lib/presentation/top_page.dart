import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/application/managers/auth_manager.dart';
import 'package:memora/presentation/widgets/group_list.dart';
import 'package:memora/presentation/widgets/group_timeline.dart';
import 'package:memora/presentation/widgets/map_display.dart';
import 'package:memora/presentation/widgets/map_display_placeholder.dart';
import 'package:memora/presentation/widgets/group_management.dart';
import 'package:memora/presentation/widgets/member_management.dart';
import 'package:memora/presentation/widgets/settings.dart';
import 'package:memora/presentation/widgets/user_drawer_header.dart';
import 'package:memora/presentation/widgets/account_settings.dart';
import 'package:memora/presentation/widgets/trip_management.dart';
import 'package:memora/application/usecases/get_current_member_usecase.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/entities/auth_state.dart';

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
        _groupTimelineInstance ?? Container(),
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

  Widget _buildBody() {
    switch (_selectedItem) {
      case NavigationItem.groupTimeline:
        return _buildGroupTimelineStack();
      case NavigationItem.mapDisplay:
        return widget.isTestEnvironment
            ? const MapDisplayPlaceholder()
            : const MapDisplay();
      case NavigationItem.groupManagement:
        if (_currentMember == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return widget.isTestEnvironment
            ? Container(
                key: const Key('group_settings'),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_work, size: 100, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'グループ管理',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'グループ管理画面',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            : GroupManagement(member: _currentMember!);
      case NavigationItem.memberManagement:
        if (_currentMember == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return widget.isTestEnvironment
            ? Container(
                key: const Key('member_settings'),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 100, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'メンバー管理',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'メンバー管理画面',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            : MemberManagement(member: _currentMember!);
      case NavigationItem.settings:
        return const Settings();
      case NavigationItem.accountSettings:
        return const AccountSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('memora'),
        leading: Builder(
          builder: (context) => IconButton(
            key: const Key('hamburger_menu'),
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Consumer<AuthManager>(
              builder: (context, authManager, child) {
                if (authManager.state.status == AuthStatus.authenticated) {
                  return UserDrawerHeader(
                    email: authManager.state.user!.loginId,
                  );
                } else {
                  return DrawerHeader(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: Text(
                      'memora',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 24,
                      ),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.timeline),
              title: const Text('グループ年表'),
              selected: _selectedItem == NavigationItem.groupTimeline,
              onTap: () =>
                  _onNavigationItemSelected(NavigationItem.groupTimeline),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('地図表示'),
              selected: _selectedItem == NavigationItem.mapDisplay,
              onTap: () => _onNavigationItemSelected(NavigationItem.mapDisplay),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('メンバー管理'),
              selected: _selectedItem == NavigationItem.memberManagement,
              onTap: () =>
                  _onNavigationItemSelected(NavigationItem.memberManagement),
            ),
            ListTile(
              leading: const Icon(Icons.group_work),
              title: const Text('グループ管理'),
              selected: _selectedItem == NavigationItem.groupManagement,
              onTap: () =>
                  _onNavigationItemSelected(NavigationItem.groupManagement),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('設定'),
              selected: _selectedItem == NavigationItem.settings,
              onTap: () => _onNavigationItemSelected(NavigationItem.settings),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('アカウント設定'),
              selected: _selectedItem == NavigationItem.accountSettings,
              onTap: () =>
                  _onNavigationItemSelected(NavigationItem.accountSettings),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('ログアウト'),
              onTap: () {
                final authManager = Provider.of<AuthManager>(
                  context,
                  listen: false,
                );
                authManager.logout();
              },
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }
}
