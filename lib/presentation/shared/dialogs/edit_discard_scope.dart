import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/presentation/notifiers/shared/edit_state_notifier.dart';
import 'package:memora/presentation/shared/dialogs/edit_discard_confirm_dialog.dart';

class EditDiscardScope extends StatelessWidget {
  const EditDiscardScope({
    super.key,
    required this.isDirty,
    required this.child,
    this.isSaving = false,
  });

  final bool isDirty;
  final bool isSaving;
  final Widget child;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [editStateNotifierProvider.overrideWith(EditStateNotifier.new)],
    child: _EditDiscardPopScope(
      isDirty: isDirty,
      isSaving: isSaving,
      child: child,
    ),
  );
}

class _EditDiscardPopScope extends ConsumerStatefulWidget {
  const _EditDiscardPopScope({
    required this.isDirty,
    required this.isSaving,
    required this.child,
  });
  final bool isDirty;
  final bool isSaving;
  final Widget child;

  @override
  ConsumerState<_EditDiscardPopScope> createState() =>
      _EditDiscardPopScopeState();
}

class _EditDiscardPopScopeState extends ConsumerState<_EditDiscardPopScope> {
  bool _confirming = false;

  Future<void> _onPop(bool didPop, Object? result) async {
    if (didPop) {
      ref.read(editStateNotifierProvider.notifier).reset();
      return;
    }
    if (widget.isSaving || _confirming) return;
    if (!widget.isDirty) {
      ref.read(editStateNotifierProvider.notifier).reset();
      Navigator.of(context).pop();
      return;
    }
    _confirming = true;
    try {
      final shouldClose = await EditDiscardConfirmDialog.show(context);
      if (mounted && shouldClose && !widget.isSaving) {
        ref.read(editStateNotifierProvider.notifier).reset();
        Navigator.of(context).pop();
      }
    } finally {
      _confirming = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(editStateNotifierProvider);
    if (editState.isDirty != widget.isDirty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(editStateNotifierProvider.notifier).setDirty(widget.isDirty);
        }
      });
    }
    return PopScope<Object?>(
      canPop: !widget.isSaving && !widget.isDirty && !editState.isDirty,
      onPopInvokedWithResult: _onPop,
      child: widget.child,
    );
  }
}
