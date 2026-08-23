class ReauthenticationRequiredException implements Exception {
  const ReauthenticationRequiredException();

  @override
  String toString() => 'この操作を続けるには再認証が必要です。';
}
