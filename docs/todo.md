# ToDo List

## DB設計・リポジトリ・ユースケース・DTO・マッパー関連

## マップの表示

## トップ画面


## アカウント管理


## グループ管理


## メンバー管理画面

## グループ管理画面

## 設定画面


## Androidウィジェット

- ウィジェットタップでアプリを開くようにする
  - Kotlin側の`WidgetItineraryDate`でキャッシュJSONの`tripId`を読み込む
  - Glanceの旅程ヘッダーまたは旅程表示領域に`actionStartActivity<MainActivity>`を設定し、`memoraWidget://openTrip?tripId=...`形式のURIを渡す
  - Flutter側で`HomeWidget.initiallyLaunchedFromHomeWidget()`と`HomeWidget.widgetClicked`を購読し、起動時と起動済みの両方でURIを受け取る
  - 受け取ったURIは専用Notifierに保留し、認証完了と`currentMember`読み込み完了後に処理する
  - `tripId`から`GetTripEntryByIdUsecase`で旅行詳細を取得し、取得できた`groupId`と`year`でグループ年表の旅行管理画面へ遷移する
  - `GroupTimelineTripManagementDestination`または`TripManagement`に初期編集対象`tripId`を渡せる口を追加する
  - `TripManagement`は旅行一覧とグループメンバー読み込み後、初期編集対象`tripId`の詳細を取得して`TripEditModal`を一度だけ開く
  - ウィジェット経由で開いた場合も、編集モーダルの親画面は対象旅行を含む年の旅行管理画面にする
  - 編集モーダルで保存、キャンセル、または破棄確認後に閉じた場合は、対象年の旅行管理画面に戻る
  - 旅行管理画面の戻る操作では対象グループの年表画面に戻り、以降は通常の年表ナビゲーションに従う
  - 未ログイン時はログイン後に保留URIを再処理し、対象旅行が取得できない場合はSnackBarで通知して通常のグループ年表へ戻す
  - 同じURIを複数回処理しないよう、処理済み`tripId`またはURIをNotifier側でクリアする

## グループ年表画面

## 旅行管理画面

## マップピンボトムシート

## 招待機能

## グループイベント

## メンバーイベント

## DVCポイント計算画面

## デザイン

## 全体

## リファクタリング

## 不具合修正
