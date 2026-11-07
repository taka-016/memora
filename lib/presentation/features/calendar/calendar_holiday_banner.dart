import 'package:memora/presentation/features/calendar/calendar_preview_text.dart';
import 'package:flutter/material.dart';

class CalendarHolidayBanner extends StatelessWidget {
  const CalendarHolidayBanner({
    super.key,
    required this.name,
    this.compact = false,
  });

  final String name;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFD32F2F),
      borderRadius: BorderRadius.circular(3),
    ),
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 2 : 8,
      vertical: compact ? 0 : 8,
    ),
    child: compact
        ? CalendarPreviewText(
            text: name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              height: 1.4,
            ),
          )
        : Text(name, style: const TextStyle(color: Colors.white, height: 1.4)),
  );
}
