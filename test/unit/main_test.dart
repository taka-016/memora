import 'package:memora/composition_root/providers/location_providers.dart';
import 'package:memora/presentation/shared/map_views/placeholder_map_view_builder.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/domain/entities/account/user.dart';
import 'package:memora/main.dart' as app;
import 'package:memora/presentation/app/app_router.dart';
import 'package:memora/presentation/app/app_routes.dart';
import 'package:memora/presentation/notifiers/android_widget/android_widget_launch_notifier.dart';
import 'package:memora/presentation/notifiers/auth/auth_notifier.dart';
import 'package:memora/presentation/app/top_page.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../helpers/fake_auth_notifier.dart';
import 'main_test.mocks.dart';

class _IdleAndroidWidgetLaunchNotifier extends AndroidWidgetLaunchNotifier {
  @override
  AndroidWidgetLaunchState build() {
    return const AndroidWidgetLaunchState();
  }
}

@GenerateMocks([GroupQueryService, MemberQueryService, AuthService])
void main() {
  late MockGroupQueryService mockGroupQueryService;
  late MockMemberQueryService mockMemberQueryService;
  late MockAuthService mockAuthService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockGroupQueryService = MockGroupQueryService();
    mockMemberQueryService = MockMemberQueryService();
    mockAuthService = MockAuthService();

    const testUser = User(
      id: 'test_user_id',
      loginId: 'test@example.com',
      isVerified: true,
    );

    final testMember = MemberDto(
      id: 'test_member_id',
      displayName: 'テストユーザー',
      kanjiLastName: 'テスト',
      kanjiFirstName: 'ユーザー',
    );

    when(mockAuthService.getCurrentUser()).thenAnswer((_) async => testUser);
    when(mockMemberQueryService.getMemberByAccountId(any))
        .thenAnswer((_) async => testMember);
    when(
      mockGroupQueryService.getGroupsWithMembersByMemberId(
        any,
        groupsOrderBy: anyNamed('groupsOrderBy'),
        membersOrderBy: anyNamed('membersOrderBy'),
      ),
    ).thenAnswer((_) async => []);
  });

  Widget createTestApp({AppMode appMode = AppMode.online}) {
    return ProviderScope(
      overrides: [
        appModeProvider.overrideWithValue(appMode),
        authNotifierProvider.overrideWith(FakeAuthNotifier.authenticated),
        memberQueryServiceProvider.overrideWithValue(mockMemberQueryService),
        authServiceProvider.overrideWithValue(mockAuthService),
        groupQueryServiceProvider.overrideWithValue(mockGroupQueryService),
        androidWidgetLaunchNotifierProvider.overrideWith(
          () => _IdleAndroidWidgetLaunchNotifier(),
        ),
        appInitialLocationProvider.overrideWithValue(
          const GroupListRoute().location,
        ),
        mapViewBuilderProvider.overrideWithValue(
          const PlaceholderMapViewBuilder(),
        ),
      ],
      child: const app.MyApp(),
    );
  }

  group('MyApp', () {
    for (final mode in ['light', 'dark']) {
      testWidgets('保存した$mode設定を起動時に反映し端末の変更より優先する', (tester) async {
        final expected = mode == 'dark' ? Brightness.dark : Brightness.light;
        final opposite = expected == Brightness.dark
            ? Brightness.light
            : Brightness.dark;
        final platform = tester.binding.platformDispatcher;
        addTearDown(platform.clearPlatformBrightnessTestValue);
        SharedPreferences.setMockInitialValues({'app_theme_mode': mode});
        platform.platformBrightnessTestValue = opposite;
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.byType(TopPage))).brightness,
          expected,
        );
        platform.platformBrightnessTestValue = expected;
        await tester.pumpAndSettle();
        platform.platformBrightnessTestValue = opposite;
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.byType(TopPage))).brightness,
          expected,
        );
      });
    }

    testWidgets('端末の明るさ変更に追従して全画面のテーマを切り替える', (tester) async {
      final platform = tester.binding.platformDispatcher;
      addTearDown(platform.clearPlatformBrightnessTestValue);
      platform.platformBrightnessTestValue = Brightness.light;
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();
      BuildContext pageContext() => tester.element(find.byType(TopPage));
      final lightTheme = Theme.of(pageContext());
      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.appBarTheme.backgroundColor, Colors.lightBlue);
      expect(lightTheme.appBarTheme.foregroundColor, Colors.white);

      platform.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      final theme = Theme.of(pageContext());
      expect(theme.brightness, Brightness.dark);
      double contrast(Color foreground, Color background) {
        final a = foreground.computeLuminance();
        final b = background.computeLuminance();
        return a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
      }

      expect(
        contrast(theme.colorScheme.onSurface, theme.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(
          theme.appBarTheme.foregroundColor!,
          theme.appBarTheme.backgroundColor!,
        ),
        greaterThanOrEqualTo(4.5),
      );

      platform.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(Theme.of(pageContext()).brightness, Brightness.light);
    });

    testWidgets('アプリ起動時にTopPageが表示される', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(TopPage), findsOneWidget);
      expect(find.text('memora'), findsOneWidget);
    });

    testWidgets('アプリのタイトルが正しく設定されている', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestApp());

      // Assert
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.title, 'memora');
    });

    testWidgets('オフライン版のアプリタイトルがmemora liteに設定されている', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(appMode: AppMode.offline));

      final MaterialApp materialApp = tester.widget(find.byType(MaterialApp));
      expect(materialApp.title, 'memora lite');
    });

    testWidgets('日本語ロケールが設定されている', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestApp());

      // Assert
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.locale, const Locale('ja'));
    });

    testWidgets('全ドロップダウンのメニュー幅を入力域に揃える', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(FakeAuthNotifier.authenticated),
            memberQueryServiceProvider.overrideWithValue(
              mockMemberQueryService,
            ),
            authServiceProvider.overrideWithValue(mockAuthService),
            groupQueryServiceProvider.overrideWithValue(mockGroupQueryService),
            androidWidgetLaunchNotifierProvider.overrideWith(
              () => _IdleAndroidWidgetLaunchNotifier(),
            ),
          ],
          child: const app.MyApp(),
        ),
      );

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(materialApp.theme!.buttonTheme.alignedDropdown, isTrue);
      expect(materialApp.routerConfig, isNotNull);
    });
  });

  group('AppClockLifecycleSync', () {
    testWidgets('バックグラウンド復帰時にアプリ共通クロックを再同期する', (WidgetTester tester) async {
      final clock = _FakeSyncableAppClock(DateTime.utc(2026, 5, 15, 12));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appClockProvider.overrideWithValue(clock)],
          child: const app.AppClockLifecycleSync(child: SizedBox.shrink()),
        ),
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(clock.syncCount, 1);
    });
  });
}

class _FakeSyncableAppClock implements AppClock {
  _FakeSyncableAppClock(this.fixedNow);

  final DateTime fixedNow;
  int syncCount = 0;

  @override
  Future<void> sync() async {
    syncCount += 1;
  }

  @override
  DateTime now() {
    return fixedNow;
  }
}
