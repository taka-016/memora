# ToDo List

## オフライン・オンラインモード対応

### 4. FactoryとComposition Rootでモードに応じた実装を選択する

- Firebase、Firestore、Crashlytics、NTP、Places SDK、地図SDK、位置情報、ネットワーク状態取得の具象型を使用している箇所を洗い出す
- DB種別ではなく認証、保存先、外部サービス、利用可能機能を一貫して決定する`AppMode.online`と`AppMode.offline`をApplication層のモデルとして定義する
- ビルド情報や将来の利用権から`AppMode`を決定する責務をモード判定へ分離し、Factoryは判定済みの`AppMode`だけを参照する
- 現在のRepository、QueryService、Transaction、AuthServiceのFactoryパターンを維持し、各Factoryが同じ`AppMode`から対応する実装を生成するように変更する
- `AuthType`と`DatabaseType`の独立した可変StateProviderを廃止し、認証と保存先が異なるモードを選択する不整合を防ぐ
- Application層とCore層には外部サービスを抽象化したインターフェースだけを配置し、具象実装をInfrastructure層へ配置する
- `main.dart`、ロガー、Androidウィジェットのバックグラウンド更新・操作コールバックから外部SDKの具象型と初期化処理を除く
- Application層のUseCaseファイルからInfrastructure層のFactoryへのimportと依存解決用Providerを除き、Providerの構成をComposition Rootへ移す
- Composition RootはFactoryが選択したDB、認証・現在利用者、時刻、ログ、地図・位置情報、Androidウィジェットの実装だけを初期化して注入する
- オンラインモードはFirestore、Firebase Auth、Crashlytics、NTP、地図・位置情報の既存実装を使用する
- オフラインモードはSQLiteと端末時刻を使用し、debugビルドだけ端末ログを出力してreleaseビルドではログを保存・送信せず、外部サービスSDKを初期化しない
- FirebaseとCrashlyticsなどの自動初期化・自動送信を無効化し、オンラインモードのComposition Rootからだけ明示的に有効化する
- アプリで利用可能な機能と利用できない理由をApplication層の共通モデルで表し、Presentation層はビルドフラグや具象データソースではなく、そのモデルを参照する
- Presentation、Domain、UseCase、Androidウィジェットにビルド情報や具象データソースによる分岐を持ち込まない
- オンラインモードとオフラインモードのデータを共有・同期・移行する機能は実装しない
- Domain層とApplication層が外側の層へ依存せず、Presentation層がDomain層とInfrastructure層を直接参照していないことをアーキテクチャテストで確認する

### 5. オフラインモードの現在利用者と利用可能機能を実装する

- 認証操作と現在利用者の解決を別の責務に分離し、オフラインモードにサインイン、メール確認、再認証などのダミー実装を要求しない
- オフラインモードの初回起動時に端末内の利用者IDと本人メンバーを作成し、以降は同じ利用者として復元する
- オフラインモードはログイン画面とアカウント設定を経由せずに起動し、オンラインモードは既存の認証導線を維持する
- 地図、地図を前提とする訪問場所管理、場所検索、現在地、共有、招待の入口と操作をオフラインモードでは非表示にする
- Deep Link、Androidウィジェット、UI以外から利用対象外のオンライン機能が呼ばれた場合は、外部サービスへ接続せず共通の利用不可結果と案内を返す
- 設定画面で利用中のモード、保存先、利用可能機能、データ消失条件を確認できるようにする

### 6. Android内部SQLite DBとデータアクセスを実装する

- `group_members`の既存データに保存されている`orderIndex`をER図へ追記する
- Context7で公式ドキュメントを確認してからDriftと必要な関連パッケージを追加する
- ER図、Domain Entity、DTO、現在のFirestore Mapperを基準に、オフラインモードで使用する業務データのSQLiteスキーマを定義する
- SQLiteスキーマに`passportNumber`と`passportExpiration`を含めず、SQLiteファイルにはアプリ独自の暗号化を適用しない
- オフラインモードで使用しない`member_invitations`と`locations`はSQLiteのテーブル、Mapper、Repository、QueryServiceを作成しない
- 主キー、外部キー、必須値、一意性、削除時の扱い、検索・並び替えに必要なindexを明示する
- Androidのアプリ内部ストレージにSQLiteファイルを作成し、DBの初期化、終了、バージョン管理、マイグレーション方針を整備する
- 日時、真偽値、nullable項目を既存Entity・DTOと相互変換できる保存形式へ統一する
- メンバー、メンバーイベント、グループ、グループメンバー、グループイベントのMapper、Repository、QueryServiceを実装する
- 旅行、タスク、旅程項目のMapper、Repository、QueryServiceを実装する
- DVCポイント契約、期間限定ポイント、利用履歴のMapper、Repository、QueryServiceを実装する
- 複数更新を原子的に保存できるSQLite用`WriteTransaction`を実装する
- 既存の並び替え、関連データの組み立て、保存・更新・削除について、保存方式ではなくアプリから観測できる振る舞いをFirestore実装と一致させる

### 7. Androidウィジェットを両方のモードへ対応する

- バックグラウンド処理用Composition Rootから、オンラインモードはFirestore、オフラインモードはSQLiteのQueryServiceと時刻実装を共通UseCaseへ注入する
- オフラインモードではバックグラウンドisolateからSQLiteを安全に初期化・終了し、FirebaseやNTPを使用しない
- 解決済みの`AppMode`を端末内へ保存し、Dartのバックグラウンド処理とKotlinのフォールバック処理が同じモードを復元できるようにする
- ウィジェット更新のWorkManager制約を復元した`AppMode`に応じて構成し、オンラインモードだけ接続済みネットワークを必須とし、オフラインモードにはネットワーク制約を設定しない
- 上記のWorkManager制約を、Dart側の通常定期登録とKotlin側のフォールバック用定期・即時登録のすべてへ適用する
- アプリ内の旅程更新後、定期更新、操作コールバック、端末再起動後に、選択中のモードのデータだけでウィジェットキャッシュを更新する

### 8. オフラインデータの手動バックアップ・復元を実装する

- SQLiteはAndroid内部ストレージのアプリ分離とOSの端末暗号化で保護し、Android Keystoreとアプリ独自のDB暗号化は使用しない
- Android 11以前とAndroid 12以降のバックアップルールを定義し、Auto Backupと端末間転送からSQLite、設定、Androidウィジェットキャッシュを除外する
- Context7で公式ドキュメントを確認してから、認証付き暗号化とシステムファイル選択に必要なパッケージを追加する
- SQLiteの生ファイルではなく、形式とスキーマのバージョンを持つ論理データとして、業務データ、端末内利用者、復元に必要な設定をエクスポートする
- バックアップファイルは利用者が入力したパスワードから導出した鍵で認証付き暗号化し、パスワードと復号鍵を端末へ保存しない
- Androidのシステムファイル選択画面を使用し、利用者が保存先と復元元を明示的に選択できるようにする
- 復元前にバックアップの形式、バージョン、完全性、パスワードを検証し、現在のオフラインデータを全件置換することへの確認を求める
- 復元は単一トランザクションで行い、検証または書き込みに失敗した場合は既存データを維持する
- バックアップのパスワードを忘れた場合は復元できないことと、バックアップ未作成時はアプリ削除・データ消去・端末故障から復元できないことをバックアップ画面と設定画面で案内する

### 9. 両方のモードを検証して関連資料を更新する

- SQLiteの保存、取得、更新、削除、並び替え、関連データ取得、制約、ロールバック、DB再オープン、スキーママイグレーションをテストする
- パスポート情報が画面、アプリ内モデル、Firestore、SQLiteへ残らず、移行スクリプトのdry-runとapplyで既存Firestoreフィールドを安全に削除できることをテストする
- 手動バックアップについて、往復復元、誤ったパスワード、改ざん、未対応バージョン、破損、復元失敗時のロールバックをテストする
- Auto Backupと端末間転送の対象にSQLite、設定、Androidウィジェットキャッシュが含まれないことを、対象Androidバージョンのバックアップルールと復元試験で確認する
- Repository、QueryService、Transaction、AuthServiceなどの全Factoryが同じ`AppMode`を参照し、モード間で実装の組み合わせが混在しないことを確認する
- `MEMORA_APP_MODE`の`online`、`offline`、`auto`、未指定、不明値についてモード判定をテストする
- オンラインモードの通常・フォールバックウィジェット更新は接続済みネットワークを要求し、オフラインモードの両更新経路は機内モードでも実行対象になることを確認する
- `MEMORA_APP_MODE=offline`を指定したrelease APKで、新規起動、再起動、機内モード、端末再起動後に対象機能とAndroidウィジェットを利用できることを確認する
- オフラインモードでFirebase、Firestore、Crashlytics、NTP、Places SDK、地図SDKが初期化されず、外部通信とオンライン機能の呼び出しが発生しないことを確認する
- `MEMORA_APP_MODE=online`を指定したrelease APKで、既存のFirestore保存、認証、共有、招待、地図、Androidウィジェットの振る舞いが維持されることを確認する
- 同じapplication IDと署名を使用した単一アプリとして、モード強制値ごとのrelease APKを作成できることを確認する
- `./check.sh`とモード強制値を受け取るrelease APK作成コマンドを継続的に実行できるようにする
- 実装結果をユースケース図、ER図、README、Firebase・環境設定、ビルド・配布手順へ反映する

## DB設計・リポジトリ・ユースケース・DTO・マッパー関連

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

## マップピンボトムシート

## 招待機能

## グループイベント

## メンバーイベント

## DVCポイント計算画面

## デザイン

## 開発環境

- KGP未対応の外部プラグイン（home_widget、workmanager_android）がbuilt-in Kotlin対応版に更新されたら対応する

## 全体

## リファクタリング

### Presentation層の責務を整理する

#### 共通方針

- Viewからの単発のUseCase呼び出しは一律に移動せず、複数UseCaseの実行順序、非同期状態、再試行、データ更新、エラー処理がViewに集中している画面を改修対象とする
- 画面・機能単位に不変な`XxxState`とRiverpodの`XxxNotifier`を作成し、初期取得状態、保持データ、操作中状態、エラーを管理する
- Notifier化では既存のhooks構成を維持することを前提とせず、データ取得や状態のライフサイクルはRiverpodの`family`、`autoDispose`、`build()`、Providerの再構築で表現する
- hooksはフォーカス、入力、スクロールなどのUI固有状態に必要な場合だけ使用し、不要になった画面は`HookConsumerWidget`から`ConsumerWidget`へ変更する
- NotifierはUseCaseの実行順序、再試行、古いリクエスト結果の破棄、作成・更新・削除後の状態反映を担当する
- Viewは状態の描画、入力、Notifierへの操作通知、Dialog・Snackbar・画面遷移の実表示を担当する
- 分離した状態遷移とUseCaseの実行順序をNotifierの単体テストで検証し、ViewのWidgetテストは状態に応じた表示とユーザー操作の通知を中心にする

#### 2. MapScreenの状態管理をNotifierへ分離する

- `MapState`と`MapNotifier`を作成し、所属グループ、選択中のグループ、訪問場所、旅行、フォーカス中の訪問場所と各取得状態を管理する
- グループ選択後の訪問場所・旅行取得、再試行、グループ切り替え時に古いリクエスト結果を破棄する処理をNotifierへ移す
- 訪問場所取得と旅行取得の部分成功・部分失敗を区別し、表示可能なデータを失敗していない取得結果だけで維持する
- 旅行詳細の再取得と、旅行更新後に旅行一覧・訪問場所一覧へ変更を反映する処理をNotifierへ移す
- `MapScreen`には地図、グループ選択、旅行編集Dialog、Snackbarの実表示を残す
- グループ切り替え、古いリクエストの完了、部分失敗、再試行、旅行更新時の状態遷移を単体テストで検証する

#### 3. MemberManagementの状態管理をNotifierへ分離する

- `MemberManagementState`と`MemberManagementNotifier`を作成し、管理対象メンバーの一覧、本人メンバーの再取得結果、初期取得状態、各操作状態とエラーを管理する
- メンバーの作成・更新・削除、招待コードの作成・更新、各処理後の一覧再取得をNotifierへ移す
- 招待コードの取得結果はNotifierの操作結果としてViewへ返し、招待DialogとSnackbarの実表示は`MemberManagement`へ残す
- 一覧取得、本人メンバーの解決、各更新処理、招待処理、更新後の再取得について、成功・失敗時の状態遷移を単体テストで検証する

#### 4. TripManagementの状態管理をNotifierへ分離する

- `TripManagementState`と`TripManagementNotifier`を作成し、対象年の旅行一覧、グループメンバー、初期取得状態、旅行の操作状態とエラーを管理する
- 旅行一覧とグループメンバーの並行取得、旅行詳細の取得、旅行の作成・更新・削除後の一覧反映をNotifierへ移す
- Androidウィジェットから指定された旅行IDの受け取り、対象旅行の解決、初期表示を一度だけ要求する状態遷移をNotifierへ移す
- `TripManagement`には旅行編集・削除Dialog、Androidウィジェットから要求された旅行Dialog、Snackbarの実表示を残す
- 並行取得の部分失敗、旅行の各更新処理、存在しない旅行ID、初期表示の重複防止を単体テストで検証する

#### 5. DvcPointCalculationScreenの状態管理をNotifierへ分離する

- `DvcPointCalculationState`と`DvcPointCalculationNotifier`を作成し、グループ、契約、期間限定ポイント、利用ポイント、表示期間、計算結果と各操作状態を管理する
- グループと各ポイントデータの並行取得、表示期間変更時の再計算、契約・期間限定ポイント・利用ポイントの保存または削除後の再取得をNotifierへ移す
- データ取得と再計算を分離し、取得済みデータから表示期間だけを変更した場合は不要な再取得を行わない
- `DvcPointCalculationScreen`には期間入力、各登録・詳細Dialog、計算結果の表、Snackbarの実表示を残す
- 並行取得、表示期間変更、保存・削除、再取得失敗時に既存データを維持する状態遷移を単体テストで検証する

#### 6. SettingsのAndroidウィジェット設定状態をNotifierへ分離する

- `SettingsState`と`SettingsNotifier`を作成し、Androidウィジェットの更新間隔、対象グループ候補、選択中の対象グループ、取得・更新状態とエラーを管理する
- 設定値とグループ一覧の取得、更新間隔の保存、対象グループの選択・解除をNotifierへ移す
- `Settings`には設定項目の描画、選択Dialog、更新結果を知らせるSnackbarの実表示を残す
- 初期取得、各設定の更新、更新失敗時の状態復元と再試行を単体テストで検証する

#### 7. AccountSettingsの再認証と更新再試行をNotifierへ分離する

- `AccountSettingsState`と`AccountSettingsNotifier`を作成し、メール変更、パスワード変更、アカウント削除の操作状態とエラーを管理する
- 認証期限切れを検出した場合の再認証要求と、再認証成功後に元の操作を一度だけ再試行する処理をNotifierへ移す
- `AccountSettings`には入力Modal、再認証Modal、成功・失敗を知らせるSnackbarの実表示を残す
- 初回成功、再認証後の成功、再認証のキャンセル・失敗、再試行の失敗について状態遷移とUseCaseの呼び出し回数を単体テストで検証する

#### 8. TopPageのAndroidウィジェット起動処理をNotifierへ分離する

- `TopPageState`と`TopPageNotifier`を作成し、既存のAndroidウィジェット起動Notifierから旅行IDを受け取り、起動処理中状態、対象旅行・グループの解決結果、エラーを管理する
- Androidウィジェットから受け取った旅行IDによる旅行取得、所属グループ一覧との照合、遷移先の解決、処理済みIDの消費をViewから分離する
- Notifierは遷移先を値として通知し、Drawerの制御、実際の画面遷移、失敗時のSnackbar表示は`TopPage`へ残す
- 初期URI読み込み中、対象旅行・グループの解決成功、存在しない旅行、取得失敗、同じ要求の重複処理防止を単体テストで検証する

#### 9. Timelineの行データ状態を機能単位のNotifierへ分離する

- 旅行はグループID・年、グループイベントとDVCはグループID、メンバーイベントはメンバーIDを引数に取得状態を管理する機能単位のStateとNotifierを作成する
- グループイベント、DVC、メンバーイベントは各UseCaseの全期間取得契約に合わせて取得結果を年別に保持し、年ごとのセルから同一条件の全件取得を重複実行しない
- `GetGroupEventsUsecase`と`GetMemberEventsUsecase`が取得失敗を空リストへ変換する処理を廃止し、例外をNotifierまで伝播させてデータなしと取得失敗を区別できるようにする
- 行Widget内のデータ取得Provider、ローカルな更新状態、保存・削除後の再取得を各機能のNotifierへ移し、複数機能へ更新を通知する必要がある場合だけ既存のMutationCoordinatorを使用する
- 行Widgetには受け取った状態の描画、編集Dialog、Notifierへの操作通知を残し、同じデータを表示する行の更新結果を一貫して反映する
- 引数ごとの状態分離、全期間取得の重複防止、保存・削除後の再取得、取得失敗からの再試行、Widget破棄後に完了した処理の扱いを単体テストで検証する

- 大規模なViewを責務単位に分割する
  - 500行を超えるPresentation層の画面・編集UIを対象に責務を確認し、状態制御、フォーム、一覧、ダイアログなどの単位へ分割する

## 不具合修正
