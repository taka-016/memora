import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/application/exceptions/external_calendar_exception.dart';
import 'package:memora/application/services/calendar/external_calendar_auth_service.dart';

class GoogleCalendarAuthService implements ExternalCalendarAuthService {
  GoogleCalendarAuthService({
    GoogleSignIn? signIn,
    GoogleSignInPlatform? platform,
  }) : _signIn = signIn ?? GoogleSignIn.instance,
       _platform = platform ?? GoogleSignInPlatform.instance;
  final GoogleSignIn _signIn;
  Future<void>? _initialization;
  final GoogleSignInPlatform _platform;
  final Map<String, ExternalCalendarAccount> _accounts = {};
  final Map<String, String> _tokens = {};
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
      throw ExternalCalendarException(
        error.code == GoogleSignInExceptionCode.canceled
            ? ExternalCalendarFailure.canceled
            : ExternalCalendarFailure.authentication,
      );
    } finally {
      done.complete();
    }
  }

  @override
  Future<ExternalCalendarAccount> connect() => _run(() async {
    await _signIn.signOut();
    final account = await _signIn.authenticate(scopeHint: scopes);
    await account.authorizationClient.authorizeScopes(scopes);
    final authorization = await account.authorizationClient
        .authorizationForScopes(scopes);
    if (authorization == null) {
      throw const ExternalCalendarException(ExternalCalendarFailure.permission);
    }
    final connected = ExternalCalendarAccount(
      id: account.id,
      email: account.email,
    );
    _accounts[account.id] = connected;
    _tokens[account.id] = authorization.accessToken;
    return connected;
  });

  @override
  void restoreAccounts(Iterable<ExternalCalendarAccount> accounts) {
    _accounts
      ..clear()
      ..addEntries(accounts.map((account) => MapEntry(account.id, account)));
    _tokens.clear();
  }

  @override
  Future<String> accessToken(String accountId, {String? invalidToken}) => _run(
    () async {
      final account = _accounts[accountId];
      if (account == null) {
        throw const ExternalCalendarException(
          ExternalCalendarFailure.authentication,
        );
      }
      if (invalidToken != null) {
        await _platform.clearAuthorizationToken(
          ClearAuthorizationTokenParams(accessToken: invalidToken),
        );
      }
      final authorization = await _platform.clientAuthorizationTokensForScopes(
        ClientAuthorizationTokensForScopesParameters(
          request: AuthorizationRequestDetails(
            scopes: scopes,
            userId: account.id,
            email: account.email,
            promptIfUnauthorized: false,
          ),
        ),
      );
      if (authorization == null) {
        throw const ExternalCalendarException(
          ExternalCalendarFailure.authentication,
        );
      }
      _tokens[accountId] = authorization.accessToken;
      return authorization.accessToken;
    },
  );

  @override
  Future<void> disconnect(String accountId) => _run(() async {
    _accounts.remove(accountId);
    final token = _tokens.remove(accountId);
    if (token != null) {
      await _platform.clearAuthorizationToken(
        ClearAuthorizationTokenParams(accessToken: token),
      );
    }
  });
}
