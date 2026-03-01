import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/presentation/notifiers/navigation_notifier.dart';
import 'package:memora/presentation/notifiers/group_timeline_navigation_notifier.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/presentation/features/map/map_screen.dart';
import 'package:memora/presentation/features/dvc/dvc_point_calculation_screen.dart';
import 'package:memora/presentation/features/group/group_management.dart';
import 'package:memora/presentation/features/member/member_management.dart';
import 'package:memora/presentation/features/setting/settings.dart';
import 'package:memora/presentation/features/account_setting/account_settings.dart';
import 'package:memora/presentation/features/trip/trip_management.dart';
import 'package:memora/presentation/features/timeline/dvc_point_usage_edit_label.dart';
import 'package:memora/domain/value_objects/auth_state.dart';
import 'package:memora/presentation/notifiers/current_member_notifier.dart';
import 'package:memora/presentation/shared/group_selection/group_selection_list.dart';

class TopPage extends HookConsumerWidget {
  final bool isTestEnvironment;

  const TopPage({super.key, this.isTestEnvironment = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        ref.read(navigationNotifierProvider.notifier).resetToDefault();
        ref
            .read(groupTimelineNavigationNotifierProvider.notifier)
            .resetToGroupList();
      });
      return null;
    }, const []);

    final currentMemberState = ref.watch(currentMemberNotifierProvider);
    final currentMember = currentMemberState.member;

    useEffect(() {
      if (currentMemberState.status != CurrentMemberStatus.error) {
        return null;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(currentMemberState.message)));
        ref.read(authNotifierProvider.notifier).logout();
      });
      return null;
    }, [currentMemberState.status, currentMemberState.message]);

    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(context, ref),
      body: _buildBody(context, ref, currentMember),
    );
  }

  void _onNavigationItemSelected(
    BuildContext context,
    WidgetRef ref,
    NavigationItem item,
  ) {
    ref.read(navigationNotifierProvider.notifier).selectItem(item);
    if (item != NavigationItem.groupTimeline) {
      ref
          .read(groupTimelineNavigationNotifierProvider.notifier)
          .resetToGroupList();
    }
    Navigator.of(context).pop();
  }

  void _onGroupSelected(WidgetRef ref, GroupDto groupWithMembers) {
    ref
        .read(groupTimelineNavigationNotifierProvider.notifier)
        .showGroupTimeline(groupWithMembers);
  }

  Widget _buildGroupTimelineStack(
    BuildContext context,
    WidgetRef ref,
    MemberDto? currentMember,
  ) {
    if (currentMember == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final timelineState = ref.watch(groupTimelineNavigationNotifierProvider);

    return IndexedStack(
      index: ref
          .read(groupTimelineNavigationNotifierProvider.notifier)
          .getStackIndex(),
      children: [
        GroupSelectionList(
          onGroupSelected: (group) => _onGroupSelected(ref, group),
          title: 'グループを選択',
          listKey: const Key('group_list'),
        ),
        isTestEnvironment
            ? _buildTestGroupTimeline(
                ref,
                timelineState
                    .groupTimelineInstance
                    ?.onDvcPointCalculationPressed,
              )
            : timelineState.groupTimelineInstance ?? Container(),
        timelineState.selectedGroupId != null &&
                timelineState.selectedYear != null
            ? TripManagement(
                groupId: timelineState.selectedGroupId!,
                year: timelineState.selectedYear!,
                onBackPressed: () => ref
                    .read(groupTimelineNavigationNotifierProvider.notifier)
                    .backFromTripManagement(),
              )
            : Container(),
        timelineState.currentScreen ==
                    GroupTimelineScreenState.dvcPointCalculation &&
                timelineState.selectedGroupId != null
            ? DvcPointCalculationScreen(
                groupId: timelineState.selectedGroupId!,
                onBackPressed: () => ref
                    .read(groupTimelineNavigationNotifierProvider.notifier)
                    .backFromDvcPointCalculation(),
              )
            : Container(),
      ],
    );
  }

  Widget _buildTestGroupTimeline(
    WidgetRef ref,
    VoidCallback? onDvcPointCalculationPressed,
  ) {
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
                    .read(groupTimelineNavigationNotifierProvider.notifier)
                    .showGroupList();
              },
            ),
            title: const Text('テストグループ'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DvcPointUsageEditLabel(onPressed: onDvcPointCalculationPressed),
              ],
            ),
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

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    MemberDto? currentMember,
  ) {
    final selectedItem = ref.watch(navigationNotifierProvider).selectedItem;

    switch (selectedItem) {
      case NavigationItem.groupTimeline:
        return _buildGroupTimelineStack(context, ref, currentMember);
      case NavigationItem.mapDisplay:
        if (currentMember == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return MapScreen(isTestEnvironment: isTestEnvironment);
      case NavigationItem.groupManagement:
        if (currentMember == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return isTestEnvironment
            ? _buildTestPlaceholder(
                key: 'group_settings',
                icon: Icons.group_work,
                title: 'グループ管理',
                subtitle: 'グループ管理画面',
              )
            : const GroupManagement();
      case NavigationItem.memberManagement:
        if (currentMember == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return isTestEnvironment
            ? _buildTestPlaceholder(
                key: 'member_settings',
                icon: Icons.people,
                title: 'メンバー管理',
                subtitle: 'メンバー管理画面',
              )
            : const MemberManagement();
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

  AppBar _buildAppBar(BuildContext context) {
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
          _buildDrawerHeader(context, ref),
          ..._buildDrawerItems(context, ref),
          const Divider(),
          _buildLogoutItem(ref),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    if (authState.status == AuthStatus.authenticated) {
      return _buildUserDrawerHeader(context, authState.user!.loginId);
    } else {
      return _buildDefaultHeader(context);
    }
  }

  Widget _buildUserDrawerHeader(BuildContext context, String email) {
    final appBarTheme = Theme.of(context).appBarTheme;

    return DrawerHeader(
      decoration: BoxDecoration(color: appBarTheme.backgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'memora',
            style: TextStyle(color: appBarTheme.foregroundColor, fontSize: 24),
          ),
          const SizedBox(height: 16),
          Text(
            email,
            style: TextStyle(
              color: appBarTheme.foregroundColor?.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultHeader(BuildContext context) {
    final appBarTheme = Theme.of(context).appBarTheme;

    return DrawerHeader(
      decoration: BoxDecoration(color: appBarTheme.backgroundColor),
      child: Text(
        'memora',
        style: TextStyle(color: appBarTheme.foregroundColor, fontSize: 24),
      ),
    );
  }

  List<Widget> _buildDrawerItems(BuildContext context, WidgetRef ref) {
    return [
      _buildDrawerItem(
        context,
        ref,
        Icons.timeline,
        'グループ年表',
        NavigationItem.groupTimeline,
      ),
      _buildDrawerItem(
        context,
        ref,
        Icons.map,
        '地図表示',
        NavigationItem.mapDisplay,
      ),
      _buildDrawerItem(
        context,
        ref,
        Icons.people,
        'メンバー管理',
        NavigationItem.memberManagement,
      ),
      _buildDrawerItem(
        context,
        ref,
        Icons.group_work,
        'グループ管理',
        NavigationItem.groupManagement,
      ),
      _buildDrawerItem(
        context,
        ref,
        Icons.settings,
        '設定',
        NavigationItem.settings,
      ),
      _buildDrawerItem(
        context,
        ref,
        Icons.account_circle,
        'アカウント設定',
        NavigationItem.accountSettings,
      ),
    ];
  }

  Widget _buildDrawerItem(
    BuildContext context,
    WidgetRef ref,
    IconData icon,
    String title,
    NavigationItem item,
  ) {
    final selectedItem = ref.watch(navigationNotifierProvider).selectedItem;

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selectedItem == item,
      onTap: () => _onNavigationItemSelected(context, ref, item),
    );
  }

  Widget _buildLogoutItem(WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.logout),
      title: const Text('ログアウト'),
      onTap: () {
        ref.read(authNotifierProvider.notifier).logout();
      },
    );
  }
}
