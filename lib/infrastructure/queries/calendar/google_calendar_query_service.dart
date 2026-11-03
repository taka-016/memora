import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/application/exceptions/external_calendar_exception.dart';
import 'package:memora/application/queries/calendar/external_calendar_query_service.dart';
import 'package:memora/application/services/calendar/external_calendar_auth_service.dart';

class GoogleCalendarQueryService implements ExternalCalendarQueryService {
  GoogleCalendarQueryService(this._auth, this._client);
  final ExternalCalendarAuthService _auth;
  final http.Client _client;

  Future<Map<String, dynamic>> _get(String accountId, Uri uri) async {
    var token = await _auth.accessToken(accountId);
    var response = await _client
        .get(uri, headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 401) {
      token = await _auth.accessToken(accountId, invalidToken: token);
      response = await _client
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 30));
    }
    if (response.statusCode != 200) {
      final failure = switch (response.statusCode) {
        401 => ExternalCalendarFailure.authentication,
        403 => _forbiddenFailure(response.body),
        404 || 410 => ExternalCalendarFailure.unavailable,
        _ => ExternalCalendarFailure.network,
      };
      throw ExternalCalendarException(failure);
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  ExternalCalendarFailure _forbiddenFailure(String body) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final errors =
        (data['error'] as Map<String, dynamic>?)?['errors'] as List? ?? [];
    if (errors.any(
      (v) => [
        'rateLimitExceeded',
        'userRateLimitExceeded',
        'quotaExceeded',
      ].contains((v as Map)['reason']),
    )) {
      return ExternalCalendarFailure.network;
    }
    return ExternalCalendarFailure.permission;
  }

  Future<List<Map<String, dynamic>>> _pages(
    String accountId,
    List<String> path,
    Map<String, String> parameters,
  ) async {
    final result = <Map<String, dynamic>>[];
    String? page;
    do {
      final uri = Uri(
        scheme: 'https',
        host: 'www.googleapis.com',
        pathSegments: ['calendar', 'v3', ...path],
        queryParameters: {...parameters, 'pageToken': ?page},
      );
      final data = await _get(accountId, uri);
      result.addAll(
        (data['items'] as List? ?? []).cast<Map<String, dynamic>>(),
      );
      page = data['nextPageToken'] as String?;
    } while (page != null && page.isNotEmpty);
    return result;
  }

  @override
  Future<List<ExternalCalendarDto>> calendars(String accountId) async {
    final items = await _pages(
      accountId,
      ['users', 'me', 'calendarList'],
      {'minAccessRole': 'reader'},
    );
    return items
        .where((v) => v['deleted'] != true)
        .map(
          (v) => ExternalCalendarDto(
            id: v['id'] as String,
            name: (v['summaryOverride'] ?? v['summary'] ?? '名称未設定') as String,
          ),
        )
        .toList();
  }

  @override
  Future<List<ExternalCalendarEventDto>> events(
    String accountId,
    List<ExternalCalendarDto> calendars,
    DateTime from,
    DateTime to,
  ) async {
    final result = <ExternalCalendarEventDto>[];
    for (final calendar in calendars) {
      final series = <String, Map<String, dynamic>>{};
      final items = await _pages(
        accountId,
        ['calendars', calendar.id, 'events'],
        {
          'timeMin': from.toUtc().toIso8601String(),
          'timeMax': to.toUtc().toIso8601String(),
          'singleEvents': 'true',
          'showDeleted': 'false',
          'orderBy': 'startTime',
        },
      );
      for (final item in items) {
        if (item['status'] == 'cancelled') continue;
        final start = item['start'] as Map<String, dynamic>;
        final end = item['end'] as Map<String, dynamic>;
        final allDay = start['date'] != null;
        final seriesId = item['recurringEventId'] as String?;
        Map<String, dynamic>? parent;
        if (seriesId != null) {
          parent = series[seriesId];
          if (parent == null) {
            parent = await _get(
              accountId,
              Uri(
                scheme: 'https',
                host: 'www.googleapis.com',
                pathSegments: [
                  'calendar',
                  'v3',
                  'calendars',
                  calendar.id,
                  'events',
                  seriesId,
                ],
              ),
            );
            series[seriesId] = parent;
          }
        }
        result.add(
          ExternalCalendarEventDto(
            accountId: accountId,
            id: item['id'] as String,
            calendarId: calendar.id,
            calendarName: calendar.name,
            title: (item['summary'] ?? '予定あり') as String,
            memo: (item['description'] ?? '') as String,
            locationName: (item['location'] ?? '') as String,
            startDateTime: allDay
                ? DateTime.parse('${start['date']}T00:00:00Z')
                : DateTime.parse(start['dateTime'] as String),
            endDateTime: allDay
                ? DateTime.parse('${end['date']}T00:00:00Z')
                      .subtract(const Duration(days: 1))
                : DateTime.parse(end['dateTime'] as String),
            isAllDay: allDay,
            isRecurring: seriesId != null,
            recurrence: List.unmodifiable(
              (parent?['recurrence'] as List? ?? const []).cast<String>(),
            ),
            timeZone:
                (parent?['start'] as Map<String, dynamic>?)?['timeZone']
                    as String?,
          ),
        );
      }
    }
    return result;
  }
}
