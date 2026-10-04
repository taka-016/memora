import 'package:flutter/material.dart';

class CalendarColorPicker extends StatelessWidget {
  const CalendarColorPicker({
    super.key,
    required this.color,
    required this.onChanged,
  });

  final Color color;
  final ValueChanged<Color>? onChanged;

  @override
  Widget build(BuildContext context) {
    final hsv = HSVColor.fromColor(color);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text('色を選択'),
            const SizedBox(width: 12),
            Icon(Icons.circle, color: color, semanticLabel: '選択した色'),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (name, value) in const [
              ('赤', 0xFFF44336),
              ('ピンク', 0xFFE91E63),
              ('紫', 0xFF9C27B0),
              ('青', 0xFF2196F3),
              ('水色', 0xFF00BCD4),
              ('緑', 0xFF4CAF50),
              ('黄', 0xFFFFEB3B),
              ('オレンジ', 0xFFFF9800),
              ('茶', 0xFF795548),
              ('灰', 0xFF607D8B),
            ])
              Tooltip(
                message: name,
                child: Semantics(
                  button: true,
                  selected: color == Color(value),
                  child: InkResponse(
                    onTap: onChanged == null
                        ? null
                        : () => onChanged!(Color(value)),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(value),
                        shape: BoxShape.circle,
                      ),
                      child: color == Color(value)
                          ? Icon(
                              Icons.check,
                              color: color.computeLuminance() > 0.179
                                  ? Colors.black
                                  : Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
        _slider('色相', hsv.hue, 360, (value) => hsv.withHue(value).toColor()),
        _slider(
          '鮮やかさ',
          hsv.saturation,
          1,
          (value) => hsv.withSaturation(value).toColor(),
        ),
        _slider('明るさ', hsv.value, 1, (value) => hsv.withValue(value).toColor()),
      ],
    );
  }

  Widget _slider(
    String name,
    double value,
    double max,
    Color Function(double) convert,
  ) => Row(
    children: [
      SizedBox(width: 64, child: Text(name)),
      Expanded(
        child: Slider(
          value: value,
          max: max,
          activeColor: color,
          semanticFormatterCallback: (value) =>
              '$name ${(value / max * 100).round()}パーセント',
          onChanged: onChanged == null
              ? null
              : (value) => onChanged!(convert(value)),
        ),
      ),
    ],
  );
}
