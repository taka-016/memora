import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/usecases/calendar/watch_calendar_launch_usecase.dart';
import 'package:memora/infrastructure/services/method_channel_calendar_launch_source.dart';

final watchCalendarLaunchUsecaseProvider = Provider<WatchCalendarLaunchUsecase?>(
  (ref) => Platform.isAndroid
      ? const WatchCalendarLaunchUsecase(MethodChannelCalendarLaunchSource())
      : null,
);

