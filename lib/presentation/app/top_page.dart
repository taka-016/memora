import 'package:memora/application/models/app_capabilities.dart';
import 'package:memora/composition_root/providers/app_providers.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/presentation/app/app_routes.dart';
import 'package:memora/presentation/notifiers/android_widget/android_widget_launch_notifier.dart';
import 'package:memora/presentation/notifiers/auth/auth_notifier.dart';
import 'package:memora/presentation/notifiers/timeline/group_timeline_group_selection_notifier.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';

class TopPage extends HookConsumerWidget {
  const TopPage({super.key, required this.selectedItem, required this.child});

  final AppNavigationItem selectedItem;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrentRoute = ModalRoute.isCurrentOf(context) ?? true;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final suppressKeyboardResize = useRef(false);
    if (!isCurrentRoute) {
      suppressKeyboardResize.value = true;
    } else if (keyboardInset == 0) {
      suppressKeyboardResize.value = false;
    }
    final resizeForKeyboard = !suppressKeyboardResize.value;
    final authenticationAvailable = ref
        .watch(appCapabilitiesProvider)
        .availability(AppFeature.authentication)
        .isAvailable;
    final scaffoldKey = useMemoized(GlobalKey<ScaffoldState>.new);
    final isDrawerOpen = useState(false);
    final memberMenu = useMemoized(MenuController.new);
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
    final isCalendarInput =
        router.state.uri.path == '/calendar' &&
        router.state.uri.queryParameters['create'] == 'true';
    final previousLocation = useRef(router.state.uri.toString());
    final pendingAndroidWidgetTripId = androidWidgetLaunchState.pendingTripId;
    final androidWidgetLaunchResolution = androidWidgetLaunchState.resolution;
    final shouldHideForAndroidWidgetLaunch =
        androidWidgetLaunchState.isInitialUriLoading ||
        pendingAndroidWidgetTripId != null ||
        androidWidgetLaunchState.pendingCalendarUri != null ||
        androidWidgetLaunchState.isSettingsLaunchPending ||
        androidWidgetLaunchState.isResolving ||
        androidWidgetLaunchResolution != null;

    useEffect(
      () {
        if (!authenticationAvailable ||
            currentMemberState.status != CurrentMemberStatus.error ||
            currentMemberState.canRetry) {
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
      },
      [
        currentMemberState.status,
        currentMemberState.message,
        currentMemberState.canRetry,
      ],
    );

    useEffect(
      () {
        if ((pendingAndroidWidgetTripId == null &&
                androidWidgetLaunchState.pendingCalendarUri == null &&
                !androidWidgetLaunchState.isSettingsLaunchPending) ||
            currentMember == null) {
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
      },
      [
        pendingAndroidWidgetTripId,
        androidWidgetLaunchState.pendingCalendarUri,
        androidWidgetLaunchState.isSettingsLaunchPending,
        currentMember?.id,
      ],
    );

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
    final isAuthenticated =
        !authenticationAvailable ||
        ref.watch(
          authNotifierProvider.select((state) => state.isAuthenticated),
        );

    useEffect(
      () {
        if (!isAuthenticated ||
            !_isPrimaryNavigation(selectedItem) ||
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
        resizeToAvoidBottomInset: resizeForKeyboard,
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
        appBar: isCalendarInput ? null : _buildAppBar(),
        drawer: isCalendarInput
            ? null
            : _buildDrawer(context, ref, closeDrawer),
        bottomNavigationBar: isCalendarInput
            ? null
            : _buildBottomNavigationBar(context, ref, closeDrawer, memberMenu),
        body:
            currentMemberState.status == CurrentMemberStatus.error &&
                (!authenticationAvailable || currentMemberState.canRetry)
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(currentMemberState.message),
                    TextButton(
                      onPressed: () => ref
                          .read(currentMemberNotifierProvider.notifier)
                          .load(),
                      child: const Text('再試行'),
                    ),
                  ],
                ),
              )
            : shouldHideForAndroidWidgetLaunch
            ? const Center(child: CircularProgressIndicator())
            : Builder(
                builder: (bodyContext) => MediaQuery.removeViewInsets(
                  context: bodyContext,
                  removeBottom: !resizeForKeyboard,
                  child: child,
                ),
              ),
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

    if (resolution case AndroidWidgetSettingsLaunchDestination()) {
      const SettingsRoute().go(context);
      return;
    }

    if (resolution case AndroidWidgetCalendarLaunchDestination()) {
      ref
          .read(groupTimelineGroupSelectionNotifierProvider.notifier)
          .setLoadedGroups(
            memberId: currentMember.id,
            groups: resolution.groups,
          );
      CalendarRoute(
        groupId: resolution.groupId,
        date: resolution.date?.toIso8601String(),
        create: resolution.create,
        eventId: resolution.eventId,
        occurrence: resolution.occurrence?.toIso8601String(),
        request: resolution.requestId,
      ).go(context);
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('指定された旅行が見つかりませんでした')));
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
    if (_isPrimaryNavigation(item)) {
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

      switch (item) {
        case AppNavigationItem.calendar:
          const CalendarRoute().go(context);
        case AppNavigationItem.shoppingList:
          const ShoppingListRoute().go(context);
        default:
          const GroupListRoute().go(context);
      }
      return;
    }

    final location = switch (item) {
      AppNavigationItem.groupTimeline => null,
      AppNavigationItem.calendar => null,
      AppNavigationItem.shoppingList => null,
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
    if (_isPrimaryNavigation(selectedItem)) {
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
          if (ref
              .watch(appCapabilitiesProvider)
              .availability(AppFeature.authentication)
              .isAvailable)
            _buildLogoutItem(ref),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, WidgetRef ref) {
    if (!ref
        .watch(appCapabilitiesProvider)
        .availability(AppFeature.authentication)
        .isAvailable) {
      return _buildUserDrawerHeader(context, 'オフラインモード');
    }
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

  bool _isPrimaryNavigation(AppNavigationItem item) =>
      item == AppNavigationItem.groupTimeline ||
      item == AppNavigationItem.calendar ||
      item == AppNavigationItem.shoppingList;

  Widget _buildBottomNavigationBar(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() closeDrawer,
    MenuController memberMenu,
  ) {
    void navigate(AppNavigationItem item) {
      unawaited(_onNavigationItemSelected(context, ref, item, closeDrawer));
    }

    final destinations = [
      (
        item: AppNavigationItem.groupTimeline,
        icon: const Icon(Icons.timeline),
        label: '年表',
      ),
      (
        item: AppNavigationItem.calendar,
        icon: const Icon(Icons.calendar_month),
        label: 'カレンダー',
      ),
      (
        item: AppNavigationItem.shoppingList,
        icon: const Icon(Icons.shopping_cart_outlined),
        label: '買い物リスト',
      ),
      if (ref
          .watch(appCapabilitiesProvider)
          .availability(AppFeature.maps)
          .isAvailable)
        (item: AppNavigationItem.map, icon: const Icon(Icons.map), label: '地図'),
      (
        item: AppNavigationItem.memberManagement,
        icon: MenuAnchor(
          controller: memberMenu,
          alignmentOffset: const Offset(0, 20),
          menuChildren: [
            MenuItemButton(
              key: const Key('member_menu_item'),
              leadingIcon: const Icon(Icons.people_outline),
              onPressed: () => navigate(AppNavigationItem.memberManagement),
              child: const Text('メンバー'),
            ),
            MenuItemButton(
              key: const Key('group_menu_item'),
              leadingIcon: const Icon(Icons.group_work_outlined),
              onPressed: () => navigate(AppNavigationItem.groupManagement),
              child: const Text('グループ'),
            ),
          ],
          child: const Icon(Icons.people, key: Key('member_menu')),
        ),
        label: 'メンバー',
      ),
    ];
    final bottomItem = selectedItem == AppNavigationItem.groupManagement
        ? AppNavigationItem.memberManagement
        : selectedItem;
    final selectedIndex = destinations.indexWhere(
      (destination) => destination.item == bottomItem,
    );
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: selectedIndex < 0 ? 0 : selectedIndex,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: [
        for (final destination in destinations)
          BottomNavigationBarItem(
            icon: destination.icon,
            label: destination.label,
          ),
      ],
      onTap: (index) {
        final item = destinations[index].item;
        if (item == AppNavigationItem.memberManagement) {
          memberMenu.isOpen ? memberMenu.close() : memberMenu.open();
        } else {
          navigate(item);
        }
      },
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
        Icons.settings,
        '設定',
        AppNavigationItem.settings,
        closeDrawer,
      ),
      if (ref
          .watch(appCapabilitiesProvider)
          .availability(AppFeature.authentication)
          .isAvailable)
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
