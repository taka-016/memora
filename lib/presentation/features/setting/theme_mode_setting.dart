import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/models/app_theme_mode.dart';
import 'package:memora/presentation/notifiers/setting/theme_settings_notifier.dart';

class ThemeModeSetting extends HookConsumerWidget {
  const ThemeModeSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionRevision = useState(0);
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
      trailing: KeyedSubtree(
        key: const Key('theme_mode_setting'),
        child: DropdownMenu<AppThemeMode>(
          selectOnly: true,
          menuStyle: const MenuStyle(
            alignment: AlignmentDirectional.bottomStart,
          ),
          requestFocusOnTap: false,
          key: ValueKey(selectionRevision.value),
          initialSelection: value.mode,
          dropdownMenuEntries: const [
            DropdownMenuEntry(value: AppThemeMode.system, label: '端末設定に従う'),
            DropdownMenuEntry(value: AppThemeMode.light, label: 'ライト'),
            DropdownMenuEntry(value: AppThemeMode.dark, label: 'ダーク'),
          ],
          enabled: !value.isSaving,
          onSelected: (mode) async {
            selectionRevision.value++;
            if (mode == null) return;
            final success = await ref
                .read(themeSettingsNotifierProvider.notifier)
                .save(mode);
            if (!context.mounted || success) return;
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('テーマを保存できませんでした')));
          },
        ),
      ),
    );
  }
}
