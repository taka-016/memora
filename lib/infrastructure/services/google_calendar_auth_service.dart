import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/application/exceptions/external_calendar_exception.dart';
import 'package:memora/application/services/calendar/external_calendar_auth_service.dart';

class GoogleCalendarAuthService implements ExternalCalendarAuthService {
  GoogleCalendarAuthService({GoogleSignIn? signIn}) : _signIn = signIn ?? GoogleSignIn.instance;
  final GoogleSignIn _signIn;
  Future<void>? _initialization;
  GoogleSignInAccount? _account;
  Future<void> _pending = Future.value();
  static const scopes = [
    'https://www.googleapis.com/auth/calendar.calendarlist.readonly',
    'https://www.googleapis.com/auth/calendar.events.readonly',
  ];

  Future<T> _run<T>(Future<T> Function() action) async {
    final previous = _pending;
    final done = Completer<void>();
    _pending = done.future;
    await previous;
    try {
      await (_initialization ??= _signIn.initialize());
      return await action();
    } on GoogleSignInException catch (error) {
      throw ExternalCalendarException(error.code == GoogleSignInExceptionCode.canceled
          ? ExternalCalendarFailure.canceled
          : ExternalCalendarFailure.authentication);
    } finally {
      done.complete();
    }
  }

  @override
  Future<ExternalCalendarAccount> connect() => _run(() async {
    _account = null;
    await _signIn.signOut();
    final account = await _signIn.authenticate(scopeHint: scopes);
    await account.authorizationClient.authorizeScopes(scopes);
    _account = account;
    return ExternalCalendarAccount(id: account.id, email: account.email);
  });

  @override
  Future<String> accessToken(String accountId, {String? invalidToken}) => _run(() async {
    final account = _account ?? await _signIn.attemptLightweightAuthentication();
    if (account == null || account.id != accountId) {
      throw const ExternalCalendarException(ExternalCalendarFailure.authentication);
    }
    _account = account;
    final client = account.authorizationClient;
    if (invalidToken != null) await client.clearAuthorizationToken(accessToken: invalidToken);
    final authorization = await client.authorizationForScopes(scopes);
    if (authorization == null) {
      throw const ExternalCalendarException(ExternalCalendarFailure.authentication);
    }
    return authorization.accessToken;
  });

  @override
  Future<void> disconnect() => _run(() async {
    _account = null;
    await _signIn.disconnect();
  });
}
