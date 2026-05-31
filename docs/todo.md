# ToDo List

## DB設計・リポジトリ・ユースケース・DTO・マッパー関連

- pinsを廃止してlocationsへ統一する
  - ER図から`pins`テーブルと`trip_entries`/`groups`から`pins`への関連を削除する
  - `Pin`エンティティ、`PinDto`、`PinMapper`、`FirestorePinMapper`を削除する
  - `TripEntry`集約、`TripEntryDto`、`TripEntryMapper`から`pins`を削除する
  - `TripEntry`の訪問開始日時・訪問終了日時に関する`pins`由来の検証を削除し、旅程項目とlocationsの検証に責務を寄せる
  - `TripEntryQueryService.getTripEntryById`の`pinsOrderBy`引数を削除する
  - `FirestoreTripEntryQueryService`で`pins`コレクションを取得して`TripEntryDto`へ詰める処理を削除する
  - `FirestoreTripEntryRepository`で旅行作成・更新・削除時に`pins`コレクションへ保存・削除する処理を削除する
  - `PinQueryService`、`FirestorePinQueryService`、`GetPinsByMemberIdUsecase`、`pinQueryServiceProvider`を削除する
  - Firestore上の既存`pins`データは破棄する想定(手動でやるため対応不要)

## マップの表示
- 地図表示画面で表示するデータをpinsからlocationsに変更する
  - `GetPinsByMemberIdUsecase`ではなく、所属グループのlocationsを取得するユースケースを使用する
  - `MapViewBuilder`、`GoogleMapViewBuilder`、`PlaceholderMapViewBuilder`、`GoogleMapView`の入力を`PinDto`から`LocationDto`中心に変更する
  - 地図上のmarker生成を`pinId`ではなく`location.id`または安定したlocation識別子で行う
  - 読み取り専用地図で表示するボトムシートを`PinDetailBottomSheet`依存からlocations用の表示へ変更する
  - 地図表示画面のテストをlocations取得・表示の期待値へ更新し、pins関連のモックを削除する

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
- 旅行管理画面からpins関連の処理を取り除く
  - pins取得・表示・更新に関する状態管理を削除する
  - pins関連のユースケース・DTO・マッパー参照を削除する
  - `TripEditModal`の`PinDto`ドラフト、ピン追加・更新・削除、`PinDetailBottomSheet`表示を削除する
  - `TripEditFormView`の`pins`入力、訪問場所一覧、ピン削除ハンドラを削除する
  - `SelectVisitLocationView`を削除する
  - 旅行保存時に`TripEntryDto.pins`へ反映していた処理を削除する
- 旅程の編集時に場所を指定できるようにする(pin廃止後に対応)
  - 場所未指定の場合は「場所を指定」ボタンを表示する
  - 「場所を指定」ボタンタップで`google_map_view`を使った小さいマップ画面を表示する
  - マップ上の長押しで新しいlocationのピンを追加できるようにする
  - 旅行に紐づく既存locationsを灰色ピンで表示する
  - 灰色ピンをタップすると「この場所を指定する」を表示し、タップしたlocationの`locationId`を旅程に設定する
  - その旅程に紐づくlocationのピンだけ赤色で表示する
  - 赤色ピンをタップすると旅程との紐付けを解除できるようにする
- 旅行編集画面の下部に旅行のlocationsマップを表示する(pin廃止後に対応)
  - 旅程ボタンとタスクボタンの下に`google_map_view`を表示する
  - この旅行に紐づくlocationsを赤色ピンで表示する
  - ピンをタップすると紐づく旅程名を表示する
  - ピンをタップした場所からlocationを削除できるようにする
  - マップの長押しで旅行に紐づくlocationを追加できるようにする
  - 長押しで追加したlocationは旅程に紐づけず、旅行にのみ紐づくlocationとして保存する

## マップピンボトムシート

- `PinDetailBottomSheet`を廃止する
  - pinsの`locationName`、`visitStartDateTime`、`visitEndDateTime`、`memo`を編集するUIを削除する
  - 地図上のlocations表示で必要な情報表示は、locations用の軽量な表示へ置き換える
  - `PinDetailBottomSheet`関連テストを削除する

## 招待機能

## グループイベント

## メンバーイベント

## DVCポイント計算画面

## デザイン

## 全体

- pins廃止に伴う仕様・テストを整理する
  - `pin_dto_test`、`pin_mapper_test`、`pin_test`、`firestore_pin_mapper_test`、`firestore_pin_query_service_test`を削除する
  - `TripEntryDto`、`TripEntry`、`TripEntryMapper`、`FirestoreTripEntryMapper`、`FirestoreTripEntryQueryService`、`FirestoreTripEntryRepository`のテストからpins期待値を削除する
  - `GoogleMapView`、`MapViewBuilder`、`TripEditModal`、`TripEditFormView`、`TripManagement`、`MapScreen`のテストをlocations前提に更新する
  - `rg "PinDto|PinQueryService|FirestorePin|pinsOrderBy|collection\\('pins'\\)|PinDetailBottomSheet|pinId"`でpins廃止漏れがないことを確認する

## リファクタリング

## 不具合修正
