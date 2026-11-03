import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/application/services/calendar/external_calendar_settings_storage.dart';

class SharedPreferencesExternalCalendarSettingsStorage
    implements ExternalCalendarSettingsStorage {
  const SharedPreferencesExternalCalendarSettingsStorage();
  String _key(String ownerId) =>
      'external_calendar_${Uri.encodeComponent(ownerId)}';

  @override
  Future<List<ExternalCalendarConnection>> load(String ownerId) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key(ownerId));
    if (raw == null) return [];
    final data = jsonDecode(raw);
    final entries = data is List ? data : [data];
    return [
      for (final entry in entries)
        ExternalCalendarConnection(
          account: ExternalCalendarAccount(
            id: entry['accountId'] as String,
            email: entry['email'] as String,
          ),
          calendarIds: (entry['calendarIds'] as List).cast<String>().toSet(),
        ),
    ];
  }

  @override
  Future<void> save(
    String ownerId,
    List<ExternalCalendarConnection> connections,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _key(ownerId),
      jsonEncode([
        for (final connection in connections)
          {
            'accountId': connection.account.id,
            'email': connection.account.email,
            'calendarIds': connection.calendarIds.toList(),
          },
      ]),
    );
    if (!saved) throw StateError('Googleカレンダーの表示設定を保存できませんでした');
  }

  @override
  Future<void> remove(String ownerId) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.remove(_key(ownerId))) {
      throw StateError('Googleカレンダーの表示設定を解除できませんでした');
    }
  }
}
