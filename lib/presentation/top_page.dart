import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/application/managers/auth_manager.dart';
import 'package:memora/presentation/widgets/group_member.dart';
import 'package:memora/presentation/widgets/group_timeline.dart';
import 'package:memora/presentation/widgets/map_display.dart';
import 'package:memora/presentation/widgets/map_display_placeholder.dart';
import 'package:memora/presentation/widgets/group_settings.dart';
import 'package:memora/presentation/widgets/member_settings.dart';
import 'package:memora/presentation/widgets/settings.dart';

enum NavigationItem {
  topPage, // トップページ (初期表示のグループ情報)
  groupTimeline, // グループ年表
  mapDisplay, // マップ表示
  groupSettings, // グループ設定
  memberSettings, // メンバー設定
  settings, // 設定
}

class TopPage extends StatefulWidget {
  final GetGroupsWithMembersUsecase getGroupsWithMembersUsecase;
  final bool isTestEnvironment;

  const TopPage({
    super.key,
    required this.getGroupsWithMembersUsecase,
    this.isTestEnvironment = false,
  });

  @override
  State<TopPage> createState() => _TopPageState();
}

class _TopPageState extends State<TopPage> {
  NavigationItem _selectedItem = NavigationItem.topPage;

  void _onNavigationItemSelected(NavigationItem item) {
    setState(() {
      _selectedItem = item;
    });
    Navigator.of(context).pop();
  }

  Widget _buildBody() {
    switch (_selectedItem) {
      case NavigationItem.topPage:
        return GroupMember(
          getGroupsWithMembersUsecase: widget.getGroupsWithMembersUsecase,
        );
      case NavigationItem.groupTimeline:
        return const GroupTimeline();
      case NavigationItem.mapDisplay:
        return widget.isTestEnvironment
            ? const MapDisplayPlaceholder()
            : const MapDisplay();
      case NavigationItem.groupSettings:
        return const GroupSettings();
      case NavigationItem.memberSettings:
        return const MemberSettings();
      case NavigationItem.settings:
        return const Settings();
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
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text(
                'memora',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('トップページ'),
              selected: _selectedItem == NavigationItem.topPage,
              onTap: () => _onNavigationItemSelected(NavigationItem.topPage),
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
              leading: const Icon(Icons.group_work),
              title: const Text('グループ設定'),
              selected: _selectedItem == NavigationItem.groupSettings,
              onTap: () =>
                  _onNavigationItemSelected(NavigationItem.groupSettings),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('メンバー設定'),
              selected: _selectedItem == NavigationItem.memberSettings,
              onTap: () =>
                  _onNavigationItemSelected(NavigationItem.memberSettings),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('設定'),
              selected: _selectedItem == NavigationItem.settings,
              onTap: () => _onNavigationItemSelected(NavigationItem.settings),
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
