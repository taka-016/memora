import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/interfaces/auth_service.dart';
import 'package:memora/application/interfaces/group_query_service.dart';
import 'package:memora/application/interfaces/pin_query_service.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
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

class TopPage extends ConsumerStatefulWidget {
  final bool isTestEnvironment;
  final MemberRepository? memberRepository;
  final AuthService? authService;
  final GroupQueryService? groupQueryService;
  final PinQueryService? pinQueryService;

  const TopPage({
    super.key,
    this.isTestEnvironment = false,
    this.memberRepository,
    this.authService,
    this.groupQueryService,
    this.pinQueryService,
  });

  @override
  ConsumerState<TopPage> createState() => _TopPageState();
}

class _TopPageState extends ConsumerState<TopPage> {
  late final GetCurrentMemberUseCase _getCurrentMemberUseCase;
  Member? _currentMember;

  @override
  void initState() {
    super.initState();

    final MemberRepository memberRepository =
        widget.memberRepository ?? ref.read(memberRepositoryProvider);
    final AuthService authService =
        widget.authService ?? ref.read(authServiceProvider);

    _getCurrentMemberUseCase = GetCurrentMemberUseCase(
      memberRepository,
      authService,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(navigationNotifierProvider.notifier).resetToDefault();
        ref
            .read(groupTimelineNavigationNotifierProvider.notifier)
            .resetToGroupList();
        _loadCurrentMember();
      }
    });
  }

  Future<void> _loadCurrentMember() async {
    try {
      final member = await _getCurrentMemberUseCase.execute();
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
            ref.read(authNotifierProvider.notifier).logout();
          }
        });
      }
    }
  }

  void _onNavigationItemSelected(NavigationItem item) {
    ref.read(navigationNotifierProvider.notifier).selectItem(item);
    if (item != NavigationItem.groupTimeline) {
      ref
          .read(groupTimelineNavigationNotifierProvider.notifier)
          .resetToGroupList();
    }
    Navigator.of(context).pop();
  }

  void _onGroupSelected(GroupWithMembersDto groupWithMembers) {
    ref
        .read(groupTimelineNavigationNotifierProvider.notifier)
        .showGroupTimeline(groupWithMembers);
  }

  Widget _buildGroupTimelineStack() {
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
          member: _currentMember!,
          onGroupSelected: (group) => _onGroupSelected(group),
          groupQueryService: widget.groupQueryService,
        ),
        widget.isTestEnvironment
            ? _buildTestGroupTimeline()
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

  Widget _buildBody() {
    final selectedItem = ref.watch(navigationNotifierProvider).selectedItem;

    switch (selectedItem) {
      case NavigationItem.groupTimeline:
        return _buildGroupTimelineStack();
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
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(context),
      body: _buildBody(),
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
    final selectedItem = ref.watch(navigationNotifierProvider).selectedItem;

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selectedItem == item,
      onTap: () => _onNavigationItemSelected(item),
    );
  }

  Widget _buildLogoutItem() {
    return ListTile(
      leading: const Icon(Icons.logout),
      title: const Text('ログアウト'),
      onTap: () {
        ref.read(authNotifierProvider.notifier).logout();
      },
    );
  }
}
