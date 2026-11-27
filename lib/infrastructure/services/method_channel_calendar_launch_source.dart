import 'package:flutter/services.dart';
import 'package:memora/application/dtos/calendar/calendar_event_draft_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_launch_request_dto.dart';
import 'package:memora/application/services/calendar/calendar_launch_source.dart';

class MethodChannelCalendarLaunchSource implements CalendarLaunchSource {
  const MethodChannelCalendarLaunchSource();
  static const _channel = MethodChannel('memora/calendar_launch');

  @override
  Stream<void> get changes => Stream<void>.multi((controller) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'launchChanged') controller.add(null);
    });
    controller.onCancel = () => _channel.setMethodCallHandler(null);
  });

  @override
  Future<CalendarLaunchRequestDto?> takePending() async {
    final Map<Object?, Object?>? data;
    try {
      data = await _channel.invokeMapMethod<Object?, Object?>('takePending');
    } on MissingPluginException {
      return null;
    }
    if (data == null) return null;
    final allDay = data['allDay'] == true;
    final start = _date(data['begin'], isUtc: allDay);
    if (data['action'] == 'view') {
      return CalendarLaunchRequestDto(date: start);
    }
    if (data['action'] != 'create') return null;
    return CalendarLaunchRequestDto(
      date: start,
      draft: CalendarEventDraftDto(
        title: data['title'] as String? ?? '',
        memo: data['description'] as String? ?? '',
        locationName: data['location'] as String? ?? '',
        start: start,
        end: _date(data['end'], isUtc: allDay),
        isAllDay: allDay,
      ),
    );
  }

  DateTime? _date(Object? value, {required bool isUtc}) {
    if (value is! int || value < -62135596800000 || value > 253402300799999) {
      return null;
    }
    final date = DateTime.fromMillisecondsSinceEpoch(value, isUtc: isUtc);
    return date.year >= 1 && date.year <= 9999 ? date : null;
  }
}
