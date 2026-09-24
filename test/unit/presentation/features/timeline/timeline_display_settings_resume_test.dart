import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/timeline/timeline_controller.dart';
import 'package:memora/presentation/features/timeline/timeline_display_settings.dart';
import 'package:memora/presentation/features/timeline/timeline_layout_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('設定画面から戻ると復元したタイムライン表示設定を反映する', (tester) async {
    SharedPreferences.setMockInitialValues({
      TimelineDisplaySettings.showAgeKey: true,
    });
    await tester.pumpWidget(const MaterialApp(home: _TimelineSettingsProbe()));
    await tester.pump();
    expect(find.text('年齢表示'), findsOneWidget);

    await tester.tap(find.text('設定へ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('復元する'));
    await tester.pumpAndSettle();

    expect(find.text('年齢非表示'), findsOneWidget);
  });
}

class _TimelineSettingsProbe extends HookWidget {
  const _TimelineSettingsProbe();

  @override
  Widget build(BuildContext context) {
    final controller = useTimelineController(
      context: context,
      baseYear: 2026,
      totalDataRows: 0,
      initialRowHeights: const [],
      layoutConfig: TimelineLayoutConfig.defaults,
    );
    return Scaffold(
      body: Column(
        children: [
          Text(controller.displaySettings.showAge ? '年齢表示' : '年齢非表示'),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    body: Builder(
                      builder: (settingsContext) => TextButton(
                        onPressed: () async {
                          await const TimelineDisplaySettings(
                            showAge: false,
                            showGrade: true,
                            showYakudoshi: true,
                          ).save();
                          if (settingsContext.mounted) {
                            Navigator.of(settingsContext).pop();
                          }
                        },
                        child: const Text('復元する'),
                      ),
                    ),
                  ),
                ),
              );
            },
            child: const Text('設定へ'),
          ),
        ],
      ),
    );
  }
}
