import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/application/exceptions/external_calendar_exception.dart';
import 'package:memora/infrastructure/services/google_calendar_auth_service.dart';

@GenerateNiceMocks([
  MockSpec<GoogleSignIn>(),
  MockSpec<GoogleSignInAccount>(),
  MockSpec<GoogleSignInAuthorizationClient>(),
  MockSpec<GoogleSignInPlatform>(),
])
import 'google_calendar_auth_service_test.mocks.dart';

void main() {
  late MockGoogleSignIn sdk;
  late MockGoogleSignInAccount account;
  late MockGoogleSignInAuthorizationClient authorization;
  late MockGoogleSignInPlatform platform;
  late GoogleCalendarAuthService service;
  const first = ExternalCalendarAccount(id: 'google', email: 'me@example.com');
  const second = ExternalCalendarAccount(
    id: 'second',
    email: 'second@example.com',
  );
  const scopes = [
    'https://www.googleapis.com/auth/calendar.calendarlist.readonly',
    'https://www.googleapis.com/auth/calendar.events.readonly',
  ];
  setUp(() {
    sdk = MockGoogleSignIn();
    account = MockGoogleSignInAccount();
    authorization = MockGoogleSignInAuthorizationClient();
    platform = MockGoogleSignInPlatform();
    when(account.id).thenReturn(first.id);
    when(account.email).thenReturn(first.email);
    when(account.authorizationClient).thenReturn(authorization);
    when(sdk.authenticate(scopeHint: scopes)).thenAnswer((_) async => account);
    when(authorization.authorizeScopes(scopes)).thenAnswer(
      (_) async => const GoogleSignInClientAuthorization(accessToken: 'access'),
    );
    when(authorization.authorizationForScopes(scopes)).thenAnswer(
      (_) async => const GoogleSignInClientAuthorization(accessToken: 'access'),
    );
    when(platform.clientAuthorizationTokensForScopes(any))
        .thenAnswer((call) async {
          final request =
              (call.positionalArguments.single
                      as ClientAuthorizationTokensForScopesParameters)
                  .request;
          expect(request.scopes, scopes);
          expect(request.promptIfUnauthorized, isFalse);
          expect(
            request.email,
            request.userId == 'google' ? first.email : second.email,
          );
          return ClientAuthorizationTokenData(
            accessToken: 'token-${request.userId}',
          );
        });
    service = GoogleCalendarAuthService(signIn: sdk, platform: platform);
  });

  test('アカウント選択と読み取り2権限への同意後にだけ連携する', () async {
    expect((await service.connect()).id, 'google');
    verifyInOrder([
      sdk.initialize(),
      sdk.signOut(),
      sdk.authenticate(scopeHint: scopes),
      authorization.authorizeScopes(scopes),
    ]);
  });

  test('復元した各アカウントをIDとメールで指定し再起動後も無操作で取得する', () async {
    service.restoreAccounts([first, second]);
    expect(await service.accessToken('google'), 'token-google');
    expect(await service.accessToken('second'), 'token-second');
    verifyNever(sdk.authenticate(scopeHint: anyNamed('scopeHint')));
    verifyNever(sdk.attemptLightweightAuthentication());
  });

  test('保存されたアカウント以外のトークンを取得しない', () async {
    service.restoreAccounts([first]);
    await expectLater(
      service.accessToken('other'),
      throwsA(isA<ExternalCalendarException>()),
    );
    verifyNever(platform.clientAuthorizationTokensForScopes(any));
  });

  test('401の古いトークンを消して同じアカウントのトークンを再取得する', () async {
    service.restoreAccounts([first]);
    expect(
      await service.accessToken('google', invalidToken: 'expired'),
      'token-google',
    );
    verifyInOrder([
      platform.clearAuthorizationToken(
        const ClearAuthorizationTokenParams(accessToken: 'expired'),
      ),
      platform.clientAuthorizationTokensForScopes(any),
    ]);
  });

  test('同意が復元できなくても自動で同意画面を開かない', () async {
    service.restoreAccounts([first]);
    when(platform.clientAuthorizationTokensForScopes(any))
        .thenAnswer((_) async => null);
    await expectLater(
      service.accessToken('google'),
      throwsA(isA<ExternalCalendarException>()),
    );
    verifyNever(authorization.authorizeScopes(any));
  });

  test('同意画面が戻っても2権限がそろわなければ連携完了にしない', () async {
    when(authorization.authorizationForScopes(scopes))
        .thenAnswer((_) async => null);
    await expectLater(
      service.connect(),
      throwsA(
        isA<ExternalCalendarException>().having(
          (v) => v.kind,
          '種別',
          ExternalCalendarFailure.permission,
        ),
      ),
    );
  });

  test('個別解除では該当トークンだけを消し他アカウントの認可を取り消さない', () async {
    service.restoreAccounts([first, second]);
    await service.accessToken('google');
    await service.accessToken('second');
    await service.disconnect('google');
    verify(
      platform.clearAuthorizationToken(
        const ClearAuthorizationTokenParams(accessToken: 'token-google'),
      ),
    ).called(1);
    verifyNever(
      platform.clearAuthorizationToken(
        const ClearAuthorizationTokenParams(accessToken: 'token-second'),
      ),
    );
    verifyNever(sdk.disconnect());
    await expectLater(
      service.accessToken('google'),
      throwsA(isA<ExternalCalendarException>()),
    );
    expect(await service.accessToken('second'), 'token-second');
  });
}
