enum ExternalCalendarFailure { authentication, permission, unavailable, network, canceled }

class ExternalCalendarException implements Exception {
  const ExternalCalendarException(this.kind);
  final ExternalCalendarFailure kind;

  String get message => switch (kind) {
    ExternalCalendarFailure.authentication => 'Googleカレンダーの再認証が必要です',
    ExternalCalendarFailure.permission => 'カレンダーの読み取り権限に再同意してください。アクセス権も確認してください',
    ExternalCalendarFailure.unavailable => 'カレンダーが削除されたか、アクセス権がありません。表示対象を確認してください',
    ExternalCalendarFailure.network => 'Googleカレンダーを取得できませんでした。通信状態を確認して再試行してください',
    ExternalCalendarFailure.canceled => 'Googleカレンダーの連携をキャンセルしました',
  };
}
