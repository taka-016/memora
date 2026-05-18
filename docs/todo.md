# ToDo List

## DB設計・リポジトリ・ユースケース・DTO・マッパー関連
- ER図のitinerary_itemsテーブル定義を元に旅程項目を実装する
  - `ItineraryItem`エンティティを作成する
  - `ItineraryItemDto`を作成する
  - `ItineraryItemMapper`を作成する
  - `FirestoreItineraryItemMapper`を作成する
  - `ItineraryItemQueryService`と`FirestoreItineraryItemQueryService`を作成し、`tripId`で旅程項目を取得できるようにする
  - `TripEntry`集約に`itineraryItems`を追加し、`TripEntryRepository`、`TripEntryQueryService`、Firestore実装、Factory配線を対応させる
  - `TripEntryDto`、`TripEntryMapper`、`FirestoreTripEntryMapper`を`itineraryItems`に対応させる
  - 保存・更新・削除時に`itinerary_items`を旅行単位で同期し、取得時は`orderIndex`順に並べる
  - `name`必須、`orderIndex`は0以上、終了日時は開始日時以降、日時は旅行期間の開始2日前から終了2日後までの範囲内であることを検証する
  - 旅程項目の取得・保存に関するユースケースとテストを追加する

## マップの表示


## トップ画面


## アカウント管理


## グループ管理


## メンバー管理画面

## グループ管理画面


## グループ年表画面

## 旅行管理画面

## マップピンボトムシート

## 招待機能

## グループイベント

## メンバーイベント

## DVCポイント計算画面
- DVCの年月選択に`showDatePicker`を直接使用しているため、共通処理へ置き換える

## デザイン

## 全体

## リファクタリング

## 不具合修正
