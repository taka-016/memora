import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/domain/value_objects/route_segment_detail.dart';

class RouteMemoEditBottomSheet extends HookWidget {
  const RouteMemoEditBottomSheet({
    super.key,
    this.initialDetail = const RouteSegmentDetail.empty(),
    required this.onChanged,
  });

  final RouteSegmentDetail initialDetail;
  final ValueChanged<RouteSegmentDetail> onChanged;

  @override
  Widget build(BuildContext context) {
    final durationController = useTextEditingController(
      text: _initialDurationText(initialDetail),
    );
    final instructionsController = useTextEditingController(
      text: initialDetail.instructions.join('\n'),
    );
    final durationFocusNode = useFocusNode();
    final instructionsFocusNode = useFocusNode();
    final currentDetail = useRef<RouteSegmentDetail>(initialDetail);

    final notifyChange = useCallback(() {
      final parsedDuration = int.tryParse(durationController.text);
      final sanitizedDuration = parsedDuration != null && parsedDuration > 0
          ? parsedDuration * 60
          : 0;
      final sanitizedInstructions = _sanitizeInstructions(
        instructionsController.text,
      );
      final nextValue = currentDetail.value.copyWith(
        durationSeconds: sanitizedDuration,
        instructions: sanitizedInstructions,
      );
      currentDetail.value = nextValue;
      onChanged(nextValue);
    }, [durationController, instructionsController, currentDetail, onChanged]);

    useEffect(() {
      void handleDurationFocus() {
        if (!durationFocusNode.hasFocus) {
          notifyChange();
        }
      }

      void handleInstructionsFocus() {
        if (!instructionsFocusNode.hasFocus) {
          notifyChange();
        }
      }

      durationFocusNode.addListener(handleDurationFocus);
      instructionsFocusNode.addListener(handleInstructionsFocus);

      return () {
        durationFocusNode.removeListener(handleDurationFocus);
        instructionsFocusNode.removeListener(handleInstructionsFocus);
        notifyChange();
      };
    }, [durationFocusNode, instructionsFocusNode, notifyChange]);

    void handleClose() {
      notifyChange();
      Navigator.of(context).maybePop(currentDetail.value);
    }

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
                    onPressed: handleClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('other_route_duration_field'),
                controller: durationController,
                focusNode: durationFocusNode,
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
                controller: instructionsController,
                focusNode: instructionsFocusNode,
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
