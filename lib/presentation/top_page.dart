import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/application/managers/auth_manager.dart';
import 'package:memora/presentation/widgets/group_member.dart';
import 'package:memora/presentation/widgets/map_display.dart';
import 'package:memora/presentation/widgets/map_display_placeholder.dart';
import 'package:memora/presentation/widgets/group_settings.dart';
import 'package:memora/presentation/widgets/member_settings.dart';
import 'package:memora/presentation/widgets/settings.dart';
import 'package:memora/presentation/widgets/user_drawer_header.dart';
import 'package:memora/presentation/widgets/account_settings.dart';
import 'package:memora/application/usecases/get_current_member_usecase.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/entities/auth_state.dart';

enum NavigationItem {
  groupTimeline, // グループ年表
  mapDisplay, // マップ表示
  groupSettings, // グループ設定
  memberSettings, // メンバー設定
  settings, // 設定
  accountSettings, // アカウント設定
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

  void _onNavigationItemSelected(NavigationItem item) {
    setState(() {
      _selectedItem = item;
    });
    Navigator.of(context).pop();
  }

  Widget _buildBody() {
    switch (_selectedItem) {
      case NavigationItem.groupTimeline:
        if (_currentMember == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return GroupMember(
          getGroupsWithMembersUsecase: widget.getGroupsWithMembersUsecase,
          member: _currentMember!,
        );
      case NavigationItem.mapDisplay:
        return widget.isTestEnvironment
            ? const MapDisplayPlaceholder()
            : const MapDisplay();
      case NavigationItem.groupSettings:
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
                        'グループ設定',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'グループ設定画面',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            : GroupSettings(member: _currentMember!);
      case NavigationItem.memberSettings:
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
                        'メンバー設定',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'メンバー設定画面',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            : MemberSettings(member: _currentMember!);
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
                  return const DrawerHeader(
                    decoration: BoxDecoration(color: Colors.deepPurple),
                    child: Text(
                      'memora',
                      style: TextStyle(color: Colors.white, fontSize: 24),
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
              title: const Text('マップ表示'),
              selected: _selectedItem == NavigationItem.mapDisplay,
              onTap: () => _onNavigationItemSelected(NavigationItem.mapDisplay),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('メンバー設定'),
              selected: _selectedItem == NavigationItem.memberSettings,
              onTap: () =>
                  _onNavigationItemSelected(NavigationItem.memberSettings),
            ),
            ListTile(
              leading: const Icon(Icons.group_work),
              title: const Text('グループ設定'),
              selected: _selectedItem == NavigationItem.groupSettings,
              onTap: () =>
                  _onNavigationItemSelected(NavigationItem.groupSettings),
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
