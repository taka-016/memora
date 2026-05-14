# UTC日時移行手順

Firestore上の既存日時をUTC基準へ正規化するための手順。

## 対象

- `members.birthday`
- `trip_entries.tripStartDate`, `trip_entries.tripEndDate`
- `pins.visitStartDate`, `pins.visitEndDate`
- `tasks.dueDate`
- `dvc_point_contracts.contractStartYearMonth`, `contractEndYearMonth`
- `dvc_limited_points.startYearMonth`, `endYearMonth`
- `dvc_point_usages.usageYearMonth`

## ドライラン

```bash
gcloud auth application-default login
dart run tools/migrations/migrate_firestore_datetimes_to_utc.dart \
  --project-id=<firebase-project-id> \
  --legacy-offset=+09:00
```

`DRY-RUN`行で、更新対象のドキュメント、フィールド、変更前後のUTC時刻を確認する。

## 反映

ドライラン結果に問題がないことを確認してから、`--commit`を付けて実行する。

```bash
dart run tools/migrations/migrate_firestore_datetimes_to_utc.dart \
  --project-id=<firebase-project-id> \
  --legacy-offset=+09:00 \
  --commit
```

`--legacy-offset`には、既存データを登録した利用者の基準タイムゾーンを指定する。
