import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/app_theme_mode.dart';
import 'package:memora/presentation/notifiers/setting/theme_settings_notifier.dart';

class ThemeModeSetting extends ConsumerWidget {
  const ThemeModeSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(themeSettingsNotifierProvider);
    final value = setting.value;
    if (value == null) {
      if (setting.hasError) {
        return TextButton(
          onPressed: () => ref.invalidate(themeSettingsNotifierProvider),
          child: const Text('テーマを再取得'),
        );
      }
      return const LinearProgressIndicator();
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('テーマ'),
      trailing: DropdownButton<AppThemeMode>(
        key: const Key('theme_mode_setting'),
        value: value.mode,
        items: const [
          DropdownMenuItem(value: AppThemeMode.system, child: Text('端末設定に従う')),
          DropdownMenuItem(value: AppThemeMode.light, child: Text('ライト')),
          DropdownMenuItem(value: AppThemeMode.dark, child: Text('ダーク')),
        ],
        onChanged: value.isSaving
            ? null
            : (mode) async {
                if (mode == null) return;
                final success = await ref
                    .read(themeSettingsNotifierProvider.notifier)
                    .save(mode);
                if (!context.mounted || success) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('テーマを保存できませんでした')));
              },
      ),
    );
  }
}
