import 'package:flutter/material.dart';
import 'package:memora/application/services/calendar/calendar_display_labels.dart';
import 'package:memora/presentation/shared/inputs/color_picker.dart';
import 'package:memora/presentation/shared/inputs/label_color_preview.dart';

class LabelColorSettings extends StatefulWidget {
  const LabelColorSettings({
    super.key,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onChanged,
    this.allowAutomaticTextColor = false,
    this.enabled = true,
    this.allDayPreviewKey = const Key('label_color_preview'),
    this.timedPreviewKey = const Key('label_color_timed_preview'),
  });

  final String label;
  final String color;
  final String? textColor;
  final void Function(String color, String? textColor) onChanged;
  final bool allowAutomaticTextColor;
  final bool enabled;
  final Key allDayPreviewKey;
  final Key timedPreviewKey;

  @override
  State<LabelColorSettings> createState() => _LabelColorSettingsState();
}

class _LabelColorSettingsState extends State<LabelColorSettings> {
  late final TextEditingController _hex;
  late Color _selectedColor;
  bool _showHex = false;

  static final _rgb = RegExp(r'^#[0-9a-fA-F]{6}$');
  Color _parse(String value) =>
      Color(0xFF000000 | int.parse(value.trim().substring(1), radix: 16));
  String _format(Color value) =>
      '#${(value.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  @override
  void initState() {
    super.initState();
    _hex = TextEditingController(text: widget.color);
    _selectedColor = _parse(widget.color);
  }

  @override
  void didUpdateWidget(covariant LabelColorSettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.color != oldWidget.color && widget.color != _hex.text) {
      _hex.text = widget.color;
      if (_rgb.hasMatch(widget.color.trim())) {
        _selectedColor = _parse(widget.color);
      }
    }
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ColorPicker(
        color: _selectedColor,
        onChanged: !widget.enabled
            ? null
            : (color) {
                setState(() {
                  _selectedColor = color;
                  _hex.text = _format(color);
                });
                widget.onChanged(_hex.text, widget.textColor);
              },
      ),
      TextButton(
        onPressed: !widget.enabled
            ? null
            : () {
                setState(() {
                  _showHex = !_showHex;
                  _hex.text = _format(_selectedColor);
                });
                widget.onChanged(_hex.text, widget.textColor);
              },
        child: Text(_showHex ? '16進数入力を閉じる' : '16進数で指定'),
      ),
      if (_showHex)
        TextFormField(
          controller: _hex,
          enabled: widget.enabled,
          decoration: const InputDecoration(
            labelText: '色（#RRGGBB）',
            helperText: '例: #2196F3',
          ),
          onChanged: (value) {
            if (_rgb.hasMatch(value.trim())) {
              setState(() => _selectedColor = _parse(value));
            }
            widget.onChanged(value, widget.textColor);
          },
          validator: (value) =>
              _rgb.hasMatch(value?.trim() ?? '') ? null : '#RRGGBB形式で入力してください',
        ),
      const SizedBox(height: 8),
      const Text('文字色'),
      Wrap(
        spacing: 12,
        children: [
          for (final (name, color) in [
            if (widget.allowAutomaticTextColor) ('自動', null),
            ('白', '#FFFFFF'),
            ('黒', '#000000'),
          ])
            ChoiceChip(
              label: Text(name),
              selected: widget.textColor?.toUpperCase() == color,
              onSelected: !widget.enabled
                  ? null
                  : (_) => widget.onChanged(_hex.text, color),
            ),
        ],
      ),
      const SizedBox(height: 12),
      LabelColorPreview(
        label: widget.label,
        color: _selectedColor,
        textColor: _parse(
          widget.textColor ??
              calendarContrastingTextColor(_format(_selectedColor)),
        ),
        allDayKey: widget.allDayPreviewKey,
        timedKey: widget.timedPreviewKey,
      ),
    ],
  );
}
