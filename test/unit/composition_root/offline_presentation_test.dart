import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/models/app_capabilities.dart';
import 'package:memora/composition_root/app_composition_root.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/providers/location_providers.dart';
import 'package:memora/infrastructure/map_views/google_map_view_builder.dart';
import 'package:memora/main.dart';

void main() {
  testWidgets('オフライン起動は外部SDKと認証を解決せず準備中の理由を表示する', (tester) async {
    final root = AppCompositionRoot(AppMode.offline);
    await root.initialize();
    await tester.pumpWidget(
      ProviderScope(overrides: root.overrides, child: const MyApp()),
    );
    await tester.pump();
    expect(find.text('端末内データの保存機能は現在準備中です。'), findsOneWidget);
    expect(find.text('ログイン'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('オフラインの地図は共通の利用不可理由を表示しSDKを生成しない', (tester) async {
    final container = AppCompositionRoot(AppMode.offline).createContainer();
    addTearDown(container.dispose);
    final builder = container.read(mapViewBuilderProvider);
    final reason = container
        .read(appCapabilitiesProvider)
        .availability(AppFeature.maps)
        .reason!;
    await tester.pumpWidget(
      MaterialApp(home: builder.createMapView(locations: const [])),
    );
    expect(find.text(reason), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('オンラインの地図は既存のGoogleMapViewBuilderを選ぶ', () {
    final container = AppCompositionRoot(AppMode.online).createContainer();
    addTearDown(container.dispose);
    expect(container.read(mapViewBuilderProvider), isA<GoogleMapViewBuilder>());
  });
}
