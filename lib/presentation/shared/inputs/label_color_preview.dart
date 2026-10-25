import 'package:flutter/material.dart';

class LabelColorPreview extends StatelessWidget {
  const LabelColorPreview({
    super.key,
    required this.label,
    required this.color,
    required this.textColor,
    this.allDayKey = const Key('label_color_preview'),
    this.timedKey = const Key('label_color_timed_preview'),
  });

  final String label;
  final Color color;
  final Color textColor;
  final Key allDayKey;
  final Key timedKey;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Text('プレビュー'),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final allDay in [true, false]) ...[
            if (!allDay) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(allDay ? '終日' : '時間指定', textAlign: TextAlign.center),
                  Container(
                    key: allDay ? allDayKey : timedKey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: allDay
                        ? BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          )
                        : BoxDecoration(
                            border: Border(
                              left: BorderSide(color: color, width: 3),
                            ),
                          ),
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        color: allDay
                            ? textColor
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ],
  );
}
