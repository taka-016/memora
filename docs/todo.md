# ToDo List

## DB設計・リポジトリ・ユースケース・DTO・マッパー関連

- locationsのドメインエンティティを作成する
  - `id`, `tripId`, `groupId`, `name`, `latitude`, `longitude`を保持する
  - trip_entryの子エンティティとして扱う
  - `latitude`と`longitude`の必須制約を表現する
- locationsのリポジトリインターフェースを作成する
  - 場所の追加・更新・削除をできるようにする
- locationsのFirestoreマッパーを作成する
  - Firestoreドキュメントとドメインエンティティを相互変換する
  - `tripId`, `groupId`, `name`, `latitude`, `longitude`の欠損や型不整合を検証する
- locationsのFirestoreリポジトリを作成する
  - 追加・更新・削除時にマッパーを通してFirestoreへ保存する
- locationsのDTOとアプリケーションマッパーを作成する
  - Presentation層へ渡す場所情報をDTOとして定義する
  - ドメインエンティティとDTOを相互変換する
- locationsのクエリサービスを作成する
  - 旅行IDで場所一覧を取得できるようにする
  - グループIDで場所一覧を取得できるようにする
  - Firestoreから取得したlocationsをDTOへ変換して返す
- locationsのユースケースを作成する
  - 旅行に紐づく場所一覧を取得する
  - グループに紐づく場所一覧を取得する
  - 場所を追加・更新・削除する
- itinerary_itemsの`locationId`追加に対応する
  - ドメインエンティティ、DTO、アプリケーションマッパーに`locationId`を追加する
  - Firestoreマッパーで`locationId`を読み書きできるようにする
  - 旅程項目の追加・更新時に`locationId`を保存できるようにする
- itinerary_itemsのクエリでlocationを紐付けて取得できるようにする
  - `locationId`が設定されている旅程項目は対応するlocationも取得する
  - `locationId`が未設定または参照先locationが存在しない場合はlocationなしで取得する
- location削除時に参照中の旅程項目の`locationId`をnullへ更新する

## マップの表示


## トップ画面


## アカウント管理


## グループ管理


## メンバー管理画面

## グループ管理画面

## 設定画面


## Androidウィジェット

## グループ年表画面

## 旅行管理画面

- 旅行編集画面から訪問場所関連のUIを廃止する
  - 訪問場所表示を削除する
  - 訪問場所編集ボタンを削除する
  - 訪問場所一覧を削除する
- 旅行管理画面からpins関連の処理を取り除く（pinsを廃止してlocationsに置き換えるための準備）
  - pins取得・表示・更新に関する状態管理を削除する
  - pins関連のユースケース・DTO・マッパー参照を削除する
- 旅程の編集時に場所を指定できるようにする
  - 場所未指定の場合は「場所を指定」ボタンを表示する
  - 「場所を指定」ボタンタップで`google_map_view`を使った小さいマップ画面を表示する
  - マップ上の長押しで新しいlocationのピンを追加できるようにする
  - 旅行に紐づく既存locationsを灰色ピンで表示する
  - 灰色ピンをタップすると「この場所を指定する」を表示し、タップしたlocationの`locationId`を旅程に設定する
  - その旅程に紐づくlocationのピンだけ赤色で表示する
  - 赤色ピンをタップすると旅程との紐付けを解除できるようにする
- 旅行編集画面の下部に旅行のlocationsマップを表示する
  - 旅程ボタンとタスクボタンの下に`google_map_view`を表示する
  - この旅行に紐づくlocationsを赤色ピンで表示する
  - ピンをタップすると紐づく旅程名を表示する
  - ピンをタップした場所からlocationを削除できるようにする
  - マップの長押しで旅行に紐づくlocationを追加できるようにする
  - 長押しで追加したlocationは旅程に紐づけず、旅行にのみ紐づくlocationとして保存する

## マップピンボトムシート

## 招待機能

## グループイベント

## メンバーイベント

## DVCポイント計算画面

## デザイン

## 全体

## リファクタリング

## 不具合修正
