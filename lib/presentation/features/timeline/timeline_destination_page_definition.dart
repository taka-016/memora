import 'package:flutter/material.dart';
import 'package:memora/presentation/notifiers/group_timeline_destination.dart';

abstract class TimelineDestinationPageDefinition {
  const TimelineDestinationPageDefinition();

  bool matches(GroupTimelineDestination destination);

  Widget buildPage({
    required BuildContext context,
    required GroupTimelineDestination destination,
    required VoidCallback onBackPressed,
  });
}
