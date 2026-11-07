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
    child: Text(
      name,
      maxLines: compact ? 1 : null,
      overflow: compact ? TextOverflow.clip : null,
      softWrap: !compact,
      style: TextStyle(
        color: Colors.white,
        fontSize: compact ? 11 : null,
        height: 1.4,
      ),
    ),
  );
}
