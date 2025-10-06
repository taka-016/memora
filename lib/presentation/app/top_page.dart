import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/interfaces/pin_query_service.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/presentation/notifiers/navigation_notifier.dart';
import 'package:memora/presentation/notifiers/group_timeline_navigation_notifier.dart';
import 'package:memora/application/dtos/group/group_with_members_dto.dart';
import 'package:memora/presentation/features/timeline/group_list.dart';
import 'package:memora/presentation/features/map/map_screen.dart';

import 'package:memora/presentation/features/group/group_management.dart';
import 'package:memora/presentation/features/member/member_management.dart';
import 'package:memora/presentation/features/setting/settings.dart';
import 'package:memora/presentation/features/account_setting/account_settings.dart';
import 'package:memora/presentation/features/trip/trip_management.dart';
import 'package:memora/application/usecases/member/get_current_member_usecase.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/value_objects/auth_state.dart';
import 'package:memora/core/app_logger.dart';

class TopPage extends StatefulWidget {
  final GetGroupsWithMembersUsecase getGroupsWithMembersUsecase;
  final bool isTestEnvironment;
  final GetCurrentMemberUseCase? getCurrentMemberUseCase;
  final PinQueryService? pinQueryService;

  const TopPage({
    super.key,
    required this.getGroupsWithMembersUsecase,
    this.isTestEnvironment = false,
    this.getCurrentMemberUseCase,
    this.pinQueryService,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final container = ProviderScope.containerOf(context);
        container.read(navigationNotifierProvider.notifier).resetToDefault();
        container
            .read(groupTimelineNavigationNotifierProvider.notifier)
            .resetToGroupList();
      }
    });
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
    } catch (e, stack) {
      logger.e(
        '_TopPageState._loadCurrentMember: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('メンバー情報の取得に失敗しました。再度ログインしてください。')),
            );
            final container = ProviderScope.containerOf(context);
            container.read(authNotifierProvider.notifier).logout();
          }
        });
      }
    }
  }

  void _onNavigationItemSelected(NavigationItem item, WidgetRef ref) {
    ref.read(navigationNotifierProvider.notifier).selectItem(item);
    if (item != NavigationItem.groupTimeline) {
      ref
          .read(groupTimelineNavigationNotifierProvider.notifier)
          .resetToGroupList();
    }
    Navigator.of(context).pop();
  }

  void _onGroupSelected(GroupWithMembersDto groupWithMembers, WidgetRef ref) {
    ref
        .read(groupTimelineNavigationNotifierProvider.notifier)
        .showGroupTimeline(groupWithMembers);
  }

  Widget _buildGroupTimelineStack(WidgetRef ref) {
    if (_currentMember == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final timelineState = ref.watch(groupTimelineNavigationNotifierProvider);

    return IndexedStack(
      index: ref
          .read(groupTimelineNavigationNotifierProvider.notifier)
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
                    .read(groupTimelineNavigationNotifierProvider.notifier)
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
                    .read(groupTimelineNavigationNotifierProvider.notifier)
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
    final selectedItem = ref.watch(navigationNotifierProvider).selectedItem;

    switch (selectedItem) {
      case NavigationItem.groupTimeline:
        return _buildGroupTimelineStack(ref);
      case NavigationItem.mapDisplay:
        if (_currentMember == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return MapScreen(
          member: _currentMember!,
          isTestEnvironment: widget.isTestEnvironment,
          pinQueryService: widget.pinQueryService,
        );
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
          appBar: _buildAppBar(context),
          drawer: _buildDrawer(context, ref),
          body: _buildBody(ref),
        );
      },
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
        final authState = ref.watch(authNotifierProvider);
        if (authState.status == AuthStatus.authenticated) {
          return _buildUserDrawerHeader(context, authState.user!.loginId);
        } else {
          return _buildDefaultHeader(context);
        }
      },
    );
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
    final selectedItem = ref.watch(navigationNotifierProvider).selectedItem;

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
          ref.read(authNotifierProvider.notifier).logout();
        },
      ),
    );
  }
}
