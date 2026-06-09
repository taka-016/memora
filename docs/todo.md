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

- Androidウィジェットの通知表示をToastに移行する
  - ウィジェットの更新・前後切り替えアクションには一意な`actionId`を付与し、Android側の背景WorkerからDart背景コールバックへ渡す
  - Dart側は`androidWidgetInteractivityCallback`で処理を実行し、処理完了後に`actionId`へ紐づく結果データ（通知種別・メッセージ・成功/失敗）をHomeWidget共有データへ保存する
  - Android側の背景WorkerはDart背景コールバックの完了を待ち、`actionId`に対応する結果データを読み取ってからToastを表示する
  - 更新ボタン押下直後ではなく、`RefreshAndroidWidgetItineraryCacheUsecase.execute`が成功した結果データを保存した後だけ「更新しました。」を表示する
  - 更新失敗時はDart側で失敗結果データを保存し、Android側でToastとして「更新に失敗しました」を表示する
  - 旅程日の前後切り替え失敗時はDart側で失敗結果データを保存し、Android側でToastとして「切り替えに失敗しました」を表示する
  - Android側でDart処理自体を開始できない、または結果データを読み取れない場合は、対象アクションに応じた失敗Toastを表示し、成功Toastは表示しない
  - Toast表示後は`actionId`に対応する結果データを削除し、古い結果による誤表示を防ぐ
  - Kotlin側ではAndroid標準の`Toast.makeText(context.applicationContext, message, Toast.LENGTH_SHORT).show()`相当をメインスレッドで実行し、Androidホーム画面上にToastを表示する
  - `ERROR_MESSAGE_KEY`、`FooterRow`、`saveErrorMessage`による通知表示は廃止または通知用途から外し、ウィジェット表示にエラーメッセージを残さない
- Androidウィジェットを1日単位などで定期的に自動更新する
  - `workmanager`を導入し、Androidの定期バックグラウンドタスクから既存のウィジェットキャッシュ更新ユースケースを呼び出す
  - アプリ起動時とウィジェット表示対象グループ設定時に、重複しない一意名で定期タスクを登録する
  - 表示対象グループが未設定の場合は定期タスク内でウィジェット表示のみ更新し、Firestore取得は行わない
  - 更新時は現在日時を基準に`selectedItineraryDateId`を再選択し、表示位置を当日以降の直近旅程へ移動する
  - ネットワーク未接続や取得失敗時は既存キャッシュを残し、ウィジェット内にエラーメッセージを保存せずToastで通知する
  - 定期更新の最小間隔はAndroidの制約に合わせ、要件上は1日単位、実装上は`Duration(hours: 24)`を基本にする
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

- マップのピンをタップして開くパネルの左右に、前後のピンへ移動するボタンを配置する
  - ボタンはパネル左右の縦マージン中央に配置する
  - `<` タップで前のピン、`>` タップで次のピンへ移動する
  - ピンの並び順は取得時の順番を使用する
  - 末尾で `>` をタップした場合は先頭へ移動し、先頭で `<` をタップした場合は末尾へ移動する

## 招待機能

## グループイベント

## メンバーイベント

## DVCポイント計算画面

## デザイン

## 全体

## リファクタリング

## 不具合修正
