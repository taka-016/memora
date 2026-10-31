import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/app_theme_mode.dart';
import 'package:memora/application/services/app_theme_mode_storage.dart';
import 'package:memora/composition_root/providers/theme_providers.dart';
import 'package:memora/presentation/features/setting/theme_mode_setting.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'theme_mode_setting_test.mocks.dart';

@GenerateMocks([AppThemeModeStorage])
void main() {
  testWidgets('保存失敗を表示して選択を保持しもう一度選び直せる', (tester) async {
    final storage = MockAppThemeModeStorage();
    when(storage.load()).thenAnswer((_) async => AppThemeMode.system);
    when(storage.save(AppThemeMode.light)).thenThrow(TestException('保存失敗'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appThemeModeStorageProvider.overrideWithValue(storage)],
        child: const MaterialApp(home: Scaffold(body: ThemeModeSetting())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('theme_mode_setting')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ライト').last);
    await tester.pumpAndSettle();
    expect(find.text('テーマを保存できませんでした'), findsOneWidget);
    expect(find.text('端末に従う'), findsOneWidget);
    when(storage.save(AppThemeMode.light)).thenAnswer((_) async {});
    await tester.tap(find.byKey(const Key('theme_mode_setting')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ライト').last);
    await tester.pumpAndSettle();
    expect(find.text('ライト'), findsOneWidget);
  });
}
