enum ExternalCalendarFailure { permission, unavailable }

class ExternalCalendarException implements Exception {
  const ExternalCalendarException(this.kind);
  final ExternalCalendarFailure kind;

  String get message => switch (kind) {
    ExternalCalendarFailure.permission => '端末の設定でカレンダーの読み取りを許可してください',
    ExternalCalendarFailure.unavailable =>
      '端末のカレンダーを取得できませんでした。同期設定と表示対象を確認してください',
  };
}
