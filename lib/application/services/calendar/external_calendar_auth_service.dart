import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';

abstract class ExternalCalendarAuthService {
  void restoreAccounts(Iterable<ExternalCalendarAccount> accounts);
  Future<ExternalCalendarAccount> connect();
  Future<String> accessToken(String accountId, {String? invalidToken});
  Future<void> disconnect(String accountId);
}
