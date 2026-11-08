import 'package:flutter/material.dart';

class CalendarPreviewText extends StatelessWidget {
  const CalendarPreviewText({
    super.key,
    required this.text,
    required this.style,
    this.centerWhenFits = true,
  });

  final String text;
  final TextStyle style;
  final bool centerWhenFits;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: DefaultTextStyle.of(context).style.merge(style),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.maybeLocaleOf(context),
        maxLines: 1,
      )..layout();
      final fits =
          !painter.didExceedMaxLines && painter.width <= constraints.maxWidth;
      painter.dispose();
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.clip,
        softWrap: false,
        textAlign: centerWhenFits && fits ? TextAlign.center : TextAlign.left,
        style: style,
      );
    },
  );
}
