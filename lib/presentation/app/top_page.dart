import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/trip/get_trip_entry_by_id_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/presentation/notifiers/navigation_notifier.dart';
import 'package:memora/presentation/notifiers/group_timeline_navigation_notifier.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/presentation/features/map/map_screen.dart';
import 'package:memora/presentation/features/group/group_management.dart';
import 'package:memora/presentation/features/member/member_management.dart';
import 'package:memora/presentation/features/setting/settings.dart';
import 'package:memora/presentation/features/account_setting/account_settings.dart';
import 'package:memora/presentation/notifiers/current_member_notifier.dart';
import 'package:memora/presentation/notifiers/android_widget_launch_notifier.dart';
import 'package:memora/presentation/shared/group_selection/group_selection_list.dart';

class TopPage extends HookConsumerWidget {
  final bool isTestEnvironment;

  const TopPage({super.key, this.isTestEnvironment = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaffoldKey = useMemoized(GlobalKey<ScaffoldState>.new);
    final isDrawerOpen = useState(false);
    final isHandlingAndroidWidgetLaunch = useState(false);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        ref.read(navigationNotifierProvider.notifier).resetToDefault();
        final notifier = ref.read(
          groupTimelineNavigationNotifierProvider.notifier,
        );
        notifier.resetToGroupList(clearGroupSelectionLoadFuture: true);
      });
      return null;
    }, const []);

    final currentMemberState = ref.watch(currentMemberNotifierProvider);
    final currentMember = currentMemberState.member;
    final androidWidgetLaunchState = ref.watch(
      androidWidgetLaunchNotifierProvider,
    );
    final pendingAndroidWidgetTripId = androidWidgetLaunchState.pendingTripId;
    final shouldHideForAndroidWidgetLaunch =
        androidWidgetLaunchState.isInitialUriLoading ||
        pendingAndroidWidgetTripId != null ||
        isHandlingAndroidWidgetLaunch.value;

    Future<void> handleAndroidWidgetLaunch(MemberDto member) async {
      isHandlingAndroidWidgetLaunch.value = true;
      try {
        await _handleAndroidWidgetLaunch(context, ref, member);
      } finally {
        if (context.mounted) {
          isHandlingAndroidWidgetLaunch.value = false;
        }
      }
    }

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

    useEffect(() {
      if (pendingAndroidWidgetTripId == null || currentMember == null) {
        return null;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        unawaited(handleAndroidWidgetLaunch(currentMember));
      });
      return null;
    }, [pendingAndroidWidgetTripId, currentMember?.id]);

    final selectedItem = ref.watch(navigationNotifierProvider).selectedItem;
    final timelineEntryState = ref.watch(
      groupTimelineNavigationNotifierProvider.select(
        (state) => (
          groupSelectionLoadFuture: state.groupSelectionLoadFuture,
          groupTimelineInstance: state.groupTimelineInstance,
        ),
      ),
    );

    useEffect(
      () {
        if (selectedItem != NavigationItem.groupTimeline ||
            currentMember == null ||
            shouldHideForAndroidWidgetLaunch) {
          return null;
        }
        if (timelineEntryState.groupSelectionLoadFuture != null ||
            timelineEntryState.groupTimelineInstance != null) {
          return null;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            return;
          }
          unawaited(
            ref
                .read(groupTimelineNavigationNotifierProvider.notifier)
                .prepareGroupTimelineEntry(currentMember),
          );
        });
        return null;
      },
      [
        selectedItem,
        currentMember?.id,
        shouldHideForAndroidWidgetLaunch,
        timelineEntryState.groupSelectionLoadFuture,
        timelineEntryState.groupTimelineInstance,
      ],
    );

    final shouldHandleAndroidBack = _shouldHandleAndroidBack(ref);
    final canPop = isDrawerOpen.value || !shouldHandleAndroidBack;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !shouldHandleAndroidBack) {
          return;
        }
        _handleAndroidBack(ref);
      },
      child: Scaffold(
        key: scaffoldKey,
        onDrawerChanged: (isOpened) {
          isDrawerOpen.value = isOpened;
        },
        appBar: _buildAppBar(context),
        drawer: _buildDrawer(context, ref),
        body: shouldHideForAndroidWidgetLaunch
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(context, ref, currentMember, selectedItem),
      ),
    );
  }

  Future<void> _handleAndroidWidgetLaunch(
    BuildContext context,
    WidgetRef ref,
    MemberDto currentMember,
  ) async {
    final tripId = ref
        .read(androidWidgetLaunchNotifierProvider.notifier)
        .takePendingTripId();
    if (tripId == null) {
      return;
    }

    try {
      final trip = await ref
          .read(getTripEntryByIdUsecaseProvider)
          .execute(tripId);
      if (!context.mounted) {
        return;
      }
      if (trip == null) {
        await _showAndroidWidgetLaunchFailure(context, ref, currentMember);
        return;
      }

      final groups = await ref
          .read(getGroupsWithMembersUsecaseProvider)
          .execute(currentMember);
      if (!context.mounted) {
        return;
      }
      final group = groups
          .where((group) => group.id == trip.groupId)
          .firstOrNull;
      if (group == null) {
        await _showAndroidWidgetLaunchFailure(context, ref, currentMember);
        return;
      }

      ref
          .read(navigationNotifierProvider.notifier)
          .selectItem(NavigationItem.groupTimeline);
      final timelineNotifier = ref.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );
      timelineNotifier.showGroupTimeline(
        group,
        clearGroupSelectionLoadFuture: true,
      );
      timelineNotifier.showTripManagement(
        trip.groupId,
        trip.year,
        initialTripId: trip.id,
      );
    } catch (e, stack) {
      logger.e(
        'TopPage._handleAndroidWidgetLaunch: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      if (context.mounted) {
        await _showAndroidWidgetLaunchFailure(context, ref, currentMember);
      }
    }
  }

  Future<void> _showAndroidWidgetLaunchFailure(
    BuildContext context,
    WidgetRef ref,
    MemberDto currentMember,
  ) async {
    ref
        .read(navigationNotifierProvider.notifier)
        .selectItem(NavigationItem.groupTimeline);
    await ref
        .read(groupTimelineNavigationNotifierProvider.notifier)
        .prepareGroupTimelineEntry(currentMember);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('指定された旅行が見つかりませんでした')));
    }
  }

  bool _shouldHandleAndroidBack(WidgetRef ref) {
    final selectedItem = ref.watch(navigationNotifierProvider).selectedItem;
    if (selectedItem != NavigationItem.groupTimeline) {
      return true;
    }

    final timelineState = ref.watch(groupTimelineNavigationNotifierProvider);
    return timelineState.destination is! GroupTimelineGroupListDestination;
  }

  void _handleAndroidBack(WidgetRef ref) {
    final selectedItem = ref.read(navigationNotifierProvider).selectedItem;
    if (selectedItem != NavigationItem.groupTimeline) {
      ref
          .read(navigationNotifierProvider.notifier)
          .selectItem(NavigationItem.groupTimeline);
      return;
    }

    ref
        .read(groupTimelineNavigationNotifierProvider.notifier)
        .handleBackNavigation();
  }

  void _onNavigationItemSelected(
    BuildContext context,
    WidgetRef ref,
    NavigationItem item,
  ) {
    final currentSelectedItem = ref
        .read(navigationNotifierProvider)
        .selectedItem;
    if (item == NavigationItem.groupTimeline) {
      if (currentSelectedItem == NavigationItem.groupTimeline) {
        Navigator.of(context).pop();
        return;
      }

      final notifier = ref.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );
      final currentMember = ref.read(currentMemberNotifierProvider).member;
      if (currentMember != null) {
        unawaited(notifier.prepareGroupTimelineEntry(currentMember));
      } else {
        notifier.resetToGroupList(clearGroupSelectionLoadFuture: true);
      }

      ref.read(navigationNotifierProvider.notifier).selectItem(item);
      Navigator.of(context).pop();
      return;
    }

    ref.read(navigationNotifierProvider.notifier).selectItem(item);
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
    final destination = timelineState.destination;
    final notifier = ref.read(groupTimelineNavigationNotifierProvider.notifier);

    final groupsFuture = timelineState.groupSelectionLoadFuture;

    if (destination is GroupTimelineGroupListDestination &&
        groupsFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return IndexedStack(
      index: notifier.getStackIndex(),
      children: [
        groupsFuture == null
            ? const SizedBox.shrink()
            : GroupSelectionList(
                onGroupSelected: (group) => _onGroupSelected(ref, group),
                title: 'グループを選択',
                listKey: const Key('group_list'),
                groupsFuture: groupsFuture,
                onRetry: () {
                  unawaited(notifier.prepareGroupTimelineEntry(currentMember));
                },
              ),
        timelineState.groupTimelineInstance ?? const SizedBox.shrink(),
        ...timelineState.destinationPageDefinitions.map((definition) {
          if (!definition.matches(destination)) {
            return const SizedBox.shrink();
          }

          return definition.buildPage(
            context: context,
            destination: destination,
            onBackPressed: notifier.backToTimeline,
          );
        }),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    MemberDto? currentMember,
    NavigationItem selectedItem,
  ) {
    switch (selectedItem) {
      case NavigationItem.groupTimeline:
        return _buildGroupTimelineStack(context, ref, currentMember);
      case NavigationItem.mapDisplay:
        if (currentMember == null) {
          return const Center(child: CircularProgressIndicator());
        }
        // Mapは外部依存（Google Map）を含むため、テスト時のみ切り替えを行う。
        return MapScreen(isTestEnvironment: isTestEnvironment);
      case NavigationItem.groupManagement:
        if (currentMember == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return const GroupManagement();
      case NavigationItem.memberManagement:
        if (currentMember == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return const MemberManagement();
      case NavigationItem.settings:
        return const Settings();
      case NavigationItem.accountSettings:
        return const AccountSettings();
    }
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

    if (!authState.isAuthenticated) {
      return _buildDefaultHeader(context);
    }

    return _buildUserDrawerHeader(context, authState.authenticatedLoginId!);
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
