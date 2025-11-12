import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtherRouteInfoFormValue extends Equatable {
  final int? durationMinutes;
  final String instructions;

  const OtherRouteInfoFormValue({this.durationMinutes, this.instructions = ''});

  const OtherRouteInfoFormValue.empty()
    : durationMinutes = null,
      instructions = '';

  OtherRouteInfoFormValue copyWith({
    int? durationMinutes,
    String? instructions,
  }) {
    return OtherRouteInfoFormValue(
      durationMinutes: durationMinutes ?? this.durationMinutes,
      instructions: instructions ?? this.instructions,
    );
  }

  bool get isEmpty {
    final hasDuration = durationMinutes != null && durationMinutes! > 0;
    final hasInstruction = instructions.trim().isNotEmpty;
    return !hasDuration && !hasInstruction;
  }

  @override
  List<Object?> get props => [durationMinutes, instructions];
}

class OtherRouteInfoBottomSheet extends StatefulWidget {
  const OtherRouteInfoBottomSheet({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final OtherRouteInfoFormValue initialValue;
  final ValueChanged<OtherRouteInfoFormValue> onChanged;

  @override
  State<OtherRouteInfoBottomSheet> createState() =>
      _OtherRouteInfoBottomSheetState();
}

class _OtherRouteInfoBottomSheetState extends State<OtherRouteInfoBottomSheet> {
  late final TextEditingController _durationController;
  late final TextEditingController _instructionsController;
  late final FocusNode _durationFocusNode;
  late final FocusNode _instructionsFocusNode;
  late OtherRouteInfoFormValue _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _durationController = TextEditingController(
      text: widget.initialValue.durationMinutes?.toString() ?? '',
    );
    _instructionsController = TextEditingController(
      text: widget.initialValue.instructions,
    );
    _durationFocusNode = FocusNode();
    _instructionsFocusNode = FocusNode();
    _durationFocusNode.addListener(() {
      if (!_durationFocusNode.hasFocus) {
        _notifyChange();
      }
    });
    _instructionsFocusNode.addListener(() {
      if (!_instructionsFocusNode.hasFocus) {
        _notifyChange();
      }
    });
  }

  @override
  void dispose() {
    _notifyChange();
    _durationFocusNode.dispose();
    _instructionsFocusNode.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final parsedDuration = int.tryParse(_durationController.text);
    final sanitizedDuration = parsedDuration != null && parsedDuration > 0
        ? parsedDuration
        : null;
    final sanitizedInstructions = _instructionsController.text.trimRight();
    final nextValue = OtherRouteInfoFormValue(
      durationMinutes: sanitizedDuration,
      instructions: sanitizedInstructions,
    );
    _currentValue = nextValue;
    widget.onChanged(nextValue);
  }

  void _handleClose() {
    _notifyChange();
    Navigator.of(context).maybePop(_currentValue);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets),
        child: Container(
          key: const Key('other_route_info_bottom_sheet'),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'その他の経路情報',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('other_route_sheet_close_button'),
                    onPressed: _handleClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('other_route_duration_field'),
                controller: _durationController,
                focusNode: _durationFocusNode,
                decoration: const InputDecoration(
                  labelText: '所要時間(分)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('other_route_instructions_field'),
                controller: _instructionsController,
                focusNode: _instructionsFocusNode,
                decoration: const InputDecoration(
                  labelText: '経路内容',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                minLines: 3,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
