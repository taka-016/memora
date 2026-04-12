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

- グループ年表の行順を将来外から指定できる形にする
  - `lib/presentation/features/timeline/default_timeline_rows.dart` で、現在固定の `旅行 -> イベント -> DVC -> groupWithMembers.members順` をそのまま並べる実装をやめ、任意の行順リストを受け取れる形に変更する
  - 今回の対応では行順リストはどこからも渡さず、未指定時のデフォルト値として現在と同じ `旅行 -> イベント -> DVC -> groupWithMembers.members順` を使う
  - 行順リストには `旅行` `イベント` `DVC` と、各メンバーを区別できる値を含められるようにして、将来指定された順序で `TimelineRowDefinition` を生成できる状態にする
- グループ年表表示の入口は「受け取れる状態」までを整える
  - `lib/presentation/notifiers/group_timeline_navigation_notifier.dart` の `showGroupTimeline` に行順リストの引数を追加し、省略時は現在のデフォルト順が使われるようにする
  - 既存呼び出し元 (`lib/presentation/app/top_page.dart`) は今回変更せず、引数省略のまま現行挙動を維持する
  - `Timeline` にはこれまでどおり生成済みの `rowDefinitions` を渡す構成のままにして、行順の切り替え責務は行生成側に閉じ込める

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

## 不具合修正
