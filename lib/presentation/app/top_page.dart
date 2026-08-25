import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/presentation/app/app_routes.dart';
import 'package:memora/presentation/notifiers/android_widget_launch_notifier.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/presentation/notifiers/group_timeline_group_selection_notifier.dart';
import 'package:memora/presentation/notifiers/current_member_notifier.dart';

class TopPage extends HookConsumerWidget {
  const TopPage({super.key, required this.selectedItem, required this.child});

  final AppNavigationItem selectedItem;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaffoldKey = useMemoized(GlobalKey<ScaffoldState>.new);
    final isDrawerOpen = useState(false);
    final drawerCloseCompleter = useRef<Completer<void>?>(null);

    Future<void> closeDrawer() {
      if (!isDrawerOpen.value) {
        return Future<void>.value();
      }
      final completer = Completer<void>();
      drawerCloseCompleter.value = completer;
      scaffoldKey.currentState?.closeDrawer();
      return completer.future;
    }

    final currentMemberState = ref.watch(currentMemberNotifierProvider);
    final currentMember = currentMemberState.member;
    final androidWidgetLaunchState = ref.watch(
      androidWidgetLaunchNotifierProvider,
    );
    final androidWidgetLaunchNotifier = ref.read(
      androidWidgetLaunchNotifierProvider.notifier,
    );
    final router = GoRouter.of(context);
    final previousLocation = useRef(router.state.uri.toString());
    final pendingAndroidWidgetTripId = androidWidgetLaunchState.pendingTripId;
    final androidWidgetLaunchResolution = androidWidgetLaunchState.resolution;
    final shouldHideForAndroidWidgetLaunch =
        androidWidgetLaunchState.isInitialUriLoading ||
        pendingAndroidWidgetTripId != null ||
        androidWidgetLaunchState.isResolving ||
        androidWidgetLaunchResolution != null;

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
        unawaited(
          ref
              .read(androidWidgetLaunchNotifierProvider.notifier)
              .resolvePendingLaunch(currentMember),
        );
      });
      return null;
    }, [pendingAndroidWidgetTripId, currentMember?.id]);

    useEffect(() {
      if (androidWidgetLaunchResolution == null || currentMember == null) {
        return null;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        final resolution = ref
            .read(androidWidgetLaunchNotifierProvider.notifier)
            .takeResolution(currentMember.id);
        if (resolution == null) {
          return;
        }
        unawaited(
          _handleAndroidWidgetLaunchResolution(
            context,
            ref,
            currentMember,
            resolution,
          ),
        );
      });
      return null;
    }, [androidWidgetLaunchResolution, currentMember?.id]);

    useEffect(() {
      void handleRouteChange() {
        final nextLocation = router.state.uri.toString();
        if (previousLocation.value == nextLocation) {
          return;
        }
        previousLocation.value = nextLocation;
        androidWidgetLaunchNotifier.cancelPendingLaunch();
      }

      router.routerDelegate.addListener(handleRouteChange);
      return () => router.routerDelegate.removeListener(handleRouteChange);
    }, [router, androidWidgetLaunchNotifier]);

    final groupSelectionMemberId = ref.watch(
      groupTimelineGroupSelectionNotifierProvider.select(
        (state) => state.memberId,
      ),
    );
    final isAuthenticated = ref.watch(
      authNotifierProvider.select((state) => state.isAuthenticated),
    );

    useEffect(
      () {
        if (!isAuthenticated ||
            selectedItem != AppNavigationItem.groupTimeline ||
            currentMember == null ||
            shouldHideForAndroidWidgetLaunch) {
          return null;
        }
        if (groupSelectionMemberId == currentMember.id) {
          return null;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            return;
          }
          unawaited(
            ref
                .read(groupTimelineGroupSelectionNotifierProvider.notifier)
                .load(currentMember),
          );
        });
        return null;
      },
      [
        isAuthenticated,
        selectedItem,
        currentMember?.id,
        shouldHideForAndroidWidgetLaunch,
        groupSelectionMemberId,
      ],
    );

    return BackButtonListener(
      onBackButtonPressed: () async {
        if (!isDrawerOpen.value) {
          return false;
        }
        unawaited(closeDrawer());
        return true;
      },
      child: Scaffold(
        key: scaffoldKey,
        onDrawerChanged: (isOpened) {
          isDrawerOpen.value = isOpened;
          if (isOpened) {
            ref
                .read(androidWidgetLaunchNotifierProvider.notifier)
                .cancelPendingLaunch();
          }
          if (!isOpened) {
            drawerCloseCompleter.value?.complete();
            drawerCloseCompleter.value = null;
          }
        },
        appBar: _buildAppBar(),
        drawer: _buildDrawer(context, ref, closeDrawer),
        body: shouldHideForAndroidWidgetLaunch
            ? const Center(child: CircularProgressIndicator())
            : child,
      ),
    );
  }

  Future<void> _handleAndroidWidgetLaunchResolution(
    BuildContext context,
    WidgetRef ref,
    MemberDto currentMember,
    AndroidWidgetLaunchResolution resolution,
  ) async {
    if (resolution case AndroidWidgetLaunchFailure()) {
      await _showAndroidWidgetLaunchFailure(context, ref, currentMember);
      return;
    }

    final destination = resolution as AndroidWidgetLaunchDestination;
    ref
        .read(groupTimelineGroupSelectionNotifierProvider.notifier)
        .setLoadedGroups(
          memberId: currentMember.id,
          groups: destination.groups,
        );
    if (!context.mounted) {
      return;
    }
    TripManagementRoute(
      groupId: destination.groupId,
      year: destination.year,
      tripId: destination.tripId,
    ).go(context);
  }

  Future<void> _showAndroidWidgetLaunchFailure(
    BuildContext context,
    WidgetRef ref,
    MemberDto currentMember,
  ) async {
    const GroupListRoute().go(context);
    await ref
        .read(groupTimelineGroupSelectionNotifierProvider.notifier)
        .load(currentMember);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('指定された旅行が見つかりませんでした')));
    }
  }

  Future<void> _onNavigationItemSelected(
    BuildContext context,
    WidgetRef ref,
    AppNavigationItem item,
    Future<void> Function() closeDrawer,
  ) async {
    ref
        .read(androidWidgetLaunchNotifierProvider.notifier)
        .cancelPendingLaunch();
    await closeDrawer();
    if (!context.mounted) {
      return;
    }
    if (selectedItem == item) {
      return;
    }
    if (item == AppNavigationItem.groupTimeline) {
      final currentMember = ref.read(currentMemberNotifierProvider).member;
      if (currentMember != null) {
        unawaited(
          ref
              .read(groupTimelineGroupSelectionNotifierProvider.notifier)
              .load(currentMember),
        );
      } else {
        ref.read(groupTimelineGroupSelectionNotifierProvider.notifier).reset();
      }

      const GroupListRoute().go(context);
      return;
    }

    final location = switch (item) {
      AppNavigationItem.groupTimeline => null,
      AppNavigationItem.map => const MapRoute().location,
      AppNavigationItem.memberManagement =>
        const MemberManagementRoute().location,
      AppNavigationItem.groupManagement =>
        const GroupManagementRoute().location,
      AppNavigationItem.settings => const SettingsRoute().location,
      AppNavigationItem.accountSettings =>
        const AccountSettingsRoute().location,
    };
    if (location == null) {
      return;
    }
    if (selectedItem == AppNavigationItem.groupTimeline) {
      unawaited(context.push<void>(location));
    } else {
      context.pushReplacement(location);
    }
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

  Drawer _buildDrawer(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() closeDrawer,
  ) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context, ref),
          ..._buildDrawerItems(context, ref, closeDrawer),
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

  List<Widget> _buildDrawerItems(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() closeDrawer,
  ) {
    return [
      _buildDrawerItem(
        context,
        ref,
        Icons.timeline,
        'グループ年表',
        AppNavigationItem.groupTimeline,
        closeDrawer,
      ),
      _buildDrawerItem(
        context,
        ref,
        Icons.map,
        '地図表示',
        AppNavigationItem.map,
        closeDrawer,
      ),
      _buildDrawerItem(
        context,
        ref,
        Icons.people,
        'メンバー管理',
        AppNavigationItem.memberManagement,
        closeDrawer,
      ),
      _buildDrawerItem(
        context,
        ref,
        Icons.group_work,
        'グループ管理',
        AppNavigationItem.groupManagement,
        closeDrawer,
      ),
      _buildDrawerItem(
        context,
        ref,
        Icons.settings,
        '設定',
        AppNavigationItem.settings,
        closeDrawer,
      ),
      _buildDrawerItem(
        context,
        ref,
        Icons.account_circle,
        'アカウント設定',
        AppNavigationItem.accountSettings,
        closeDrawer,
      ),
    ];
  }

  ListTile _buildDrawerItem(
    BuildContext context,
    WidgetRef ref,
    IconData icon,
    String title,
    AppNavigationItem item,
    Future<void> Function() closeDrawer,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selectedItem == item,
      onTap: () {
        unawaited(_onNavigationItemSelected(context, ref, item, closeDrawer));
      },
    );
  }

  ListTile _buildLogoutItem(WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.logout),
      title: const Text('ログアウト'),
      onTap: () {
        ref.read(authNotifierProvider.notifier).logout();
      },
    );
  }
}
