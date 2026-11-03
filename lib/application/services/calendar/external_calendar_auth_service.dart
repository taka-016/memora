import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';

abstract class ExternalCalendarAuthService {
  Future<ExternalCalendarAccount> connect();
  Future<String> accessToken(String accountId, {String? invalidToken});
  Future<void> disconnect();
}
