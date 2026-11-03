import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/exceptions/external_calendar_exception.dart';
import 'package:memora/infrastructure/services/google_calendar_auth_service.dart';

@GenerateNiceMocks([
  MockSpec<GoogleSignIn>(),
  MockSpec<GoogleSignInAccount>(),
  MockSpec<GoogleSignInAuthorizationClient>(),
])
import 'google_calendar_auth_service_test.mocks.dart';

void main() {
  late MockGoogleSignIn sdk;
  late MockGoogleSignInAccount account;
  late MockGoogleSignInAuthorizationClient authorization;
  late GoogleCalendarAuthService service;
  const scopes = [
    'https://www.googleapis.com/auth/calendar.calendarlist.readonly',
    'https://www.googleapis.com/auth/calendar.events.readonly',
  ];
  setUp(() {
    sdk = MockGoogleSignIn();
    account = MockGoogleSignInAccount();
    authorization = MockGoogleSignInAuthorizationClient();
    when(account.id).thenReturn('google');
    when(account.email).thenReturn('me@example.com');
    when(account.authorizationClient).thenReturn(authorization);
    when(sdk.authenticate(scopeHint: scopes)).thenAnswer((_) async => account);
    when(sdk.attemptLightweightAuthentication())
        .thenAnswer((_) async => account);
    when(authorization.authorizeScopes(scopes)).thenAnswer(
      (_) async => const GoogleSignInClientAuthorization(accessToken: 'access'),
    );
    when(authorization.authorizationForScopes(scopes)).thenAnswer(
      (_) async => const GoogleSignInClientAuthorization(accessToken: 'access'),
    );
    service = GoogleCalendarAuthService(signIn: sdk);
  });
  test('Googleのアカウント選択と読み取り2権限への同意後にだけ連携する', () async {
    expect((await service.connect()).id, 'google');
    verifyInOrder([
      sdk.initialize(),
      sdk.signOut(),
      sdk.authenticate(scopeHint: scopes),
      authorization.authorizeScopes(scopes),
    ]);
  });
  test('復元したアカウントが異なるとトークンを取得しない', () async {
    await expectLater(
      service.accessToken('other'),
      throwsA(
        isA<ExternalCalendarException>().having(
          (v) => v.kind,
          '種別',
          ExternalCalendarFailure.authentication,
        ),
      ),
    );
    verifyNever(authorization.authorizationForScopes(any));
  });
  test('401の古いトークンをSDKから消し自動取得だけを行う', () async {
    expect(
      await service.accessToken('google', invalidToken: 'expired'),
      'access',
    );
    verifyInOrder([
      authorization.clearAuthorizationToken(accessToken: 'expired'),
      authorization.authorizationForScopes(scopes),
    ]);
    verifyNever(authorization.authorizeScopes(any));
  });
  test('同意が復元できなければ自動で同意画面を開かず再認証を求める', () async {
    when(authorization.authorizationForScopes(any))
        .thenAnswer((_) async => null);
    await expectLater(
      service.accessToken('google'),
      throwsA(isA<ExternalCalendarException>()),
    );
    verifyNever(authorization.authorizeScopes(any));
  });
  test('同意画面が戻っても2権限がそろわなければ連携完了にしない', () async {
    when(authorization.authorizationForScopes(scopes)).thenAnswer((_) async => null);
    await expectLater(service.connect(), throwsA(isA<ExternalCalendarException>().having((v) => v.kind, '種別', ExternalCalendarFailure.permission)));
  });
  test('解除はSDKの認可を取り消す', () async {
    await service.disconnect();
    verify(sdk.disconnect()).called(1);
  });
}
