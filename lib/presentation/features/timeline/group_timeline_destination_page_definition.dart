import 'package:flutter/material.dart';
import 'package:memora/presentation/notifiers/group_timeline_destination.dart';

abstract class GroupTimelineDestinationPageDefinition {
  const GroupTimelineDestinationPageDefinition();

  bool matches(GroupTimelineDestination destination);

  Widget buildPage({
    required BuildContext context,
    required GroupTimelineDestination destination,
    required VoidCallback onBackPressed,
  });
}
