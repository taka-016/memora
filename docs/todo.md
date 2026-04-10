# ToDo List

## DB設計・リポジトリ・ユースケース・DTO・マッパー関連

- FirestoreのMapperは新規作成用と更新用で出し分ける方針に統一する
  - 新規作成時は`createdAt`と`updatedAt`の両方に`FieldValue.serverTimestamp()`を設定する
  - 更新時は`createdAt`を更新データに含めず、`updatedAt`のみ更新する
- FirestoreのRepositoryは既存ドキュメント更新時に全置換の`set`を使わず、`update`で差分更新する方針に統一する
  - 新規作成時のみ`add`または新規`doc`への`set`を使用する
  - 既存フィールドを保持したいが`update`を使えないケースがある場合のみ、理由を明記したうえで`set(..., SetOptions(merge: true))`を許容する

## マップの表示


## トップ画面


## アカウント管理


## グループ管理


## メンバー管理画面

## グループ管理画面


## グループ年表画面

## 旅行管理画面

## 地図画面

## マップピンボトムシート


## 招待機能

- 招待コードで紐づけたmemberを更新した後、使用済み招待コードのレコードは削除する
- 作成から24時間経過した招待コードは無効とする

## グループイベント

## DVCポイント計算画面

## デザイン

## 全体

## リファクタリング

- グループ年表の次画面遷移を、遷移先を表す共通表現（新規型。仮称: `GroupTimelineDestination`）に整理し、行クラスごとの個別コールバック依存をなくす
- `TripRow` と `DvcRow` の行実装を共通化するのではなく、遷移要求を受け渡す引数インタフェースのみを共通化し、`buildDefaultTimelineRows()` の個別引数依存を解消する
- `group_timeline_navigation_notifier.dart` の `selectedGroupId` / `selectedYear` / 個別画面遷移管理を共通の遷移先管理へ整理する
- `_buildGroupTimelineStack` の個別画面分岐を共通の遷移先に基づく描画へ整理する
- グループ年表遷移まわりの notifier / widget テストを共通化後の設計に合わせて更新する

## 不具合修正
