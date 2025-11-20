import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memora/domain/value_objects/route_segment_detail.dart';

class RouteMemoEditBottomSheet extends StatefulWidget {
  const RouteMemoEditBottomSheet({
    super.key,
    this.initialDetail = const RouteSegmentDetail.empty(),
    required this.onChanged,
  });

  final RouteSegmentDetail initialDetail;
  final ValueChanged<RouteSegmentDetail> onChanged;

  @override
  State<RouteMemoEditBottomSheet> createState() =>
      _RouteMemoEditBottomSheetState();
}

class _RouteMemoEditBottomSheetState extends State<RouteMemoEditBottomSheet> {
  late final TextEditingController _durationController;
  late final TextEditingController _instructionsController;
  late final FocusNode _durationFocusNode;
  late final FocusNode _instructionsFocusNode;
  late RouteSegmentDetail _currentDetail;

  @override
  void initState() {
    super.initState();
    _currentDetail = widget.initialDetail;
    _durationController = TextEditingController(
      text: _initialDurationText(widget.initialDetail),
    );
    _instructionsController = TextEditingController(
      text: widget.initialDetail.instructions.join('\n'),
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
        ? parsedDuration * 60
        : 0;
    final sanitizedInstructions = _sanitizeInstructions(
      _instructionsController.text,
    );
    final nextValue = _currentDetail.copyWith(
      durationSeconds: sanitizedDuration,
      instructions: sanitizedInstructions,
    );
    _currentDetail = nextValue;
    widget.onChanged(nextValue);
  }

  void _handleClose() {
    _notifyChange();
    Navigator.of(context).maybePop(_currentDetail);
  }

  String _initialDurationText(RouteSegmentDetail detail) {
    if (detail.durationSeconds <= 0) {
      return '';
    }
    final minutes = (detail.durationSeconds / 60).ceil();
    return minutes.toString();
  }

  List<String> _sanitizeInstructions(String raw) {
    return raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
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
