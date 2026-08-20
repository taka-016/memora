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

- Viewからの単発のUseCase呼び出しは一律に移動せず、複数UseCaseの実行順序、非同期処理の競合、部分失敗、再試行、更新後の整合性維持がViewに集中している機能を改修対象とする
- Viewが継続して描画する非同期の取得結果は`FutureProvider`、複雑な状態遷移や更新後の整合性維持は`Notifier`、ユーザー操作や初期Dialog表示の直前に一度だけ取得する結果はViewからUseCaseを実行し、複数画面で再利用する業務フローはApplication層のUseCaseへ配置する
- UseCaseの直接参照を隠すことだけを目的に、Viewが監視しない単発取得をProviderで包まない
- 選択候補など関連付けが未確定のデータは取得元のDTOのまま扱い、関連先ID、権限、表示順を持つDTOへの変換は選択または保存によって関連付けが確定する時点で行う
- 責務の分離とファイルの分割は別に判断し、単一View専用の小さなProviderや補助処理はViewと同じファイルに置く。複数ファイルから再利用する場合や、ファイル肥大化により可読性が損なわれる場合だけ別ファイルへ分割する
- `XxxState`には描画、操作可否、再試行に継続して必要な状態だけを保持する。Stateの更新に関係する単発の操作結果はNotifierの戻り値または例外、描画中に監視する取得結果は`FutureProvider`、イベント内だけで使う取得結果はUseCaseの戻り値としてViewへ返す
- 操作中状態は進捗表示や操作無効化などViewの描画に使用する場合だけStateへ含め、重複実行防止だけが目的の場合はNotifier内部で管理する
- Notifier化では既存のhooks構成を維持することを前提とせず、データ取得や状態のライフサイクルはRiverpodの`family`、`autoDispose`、`build()`、Providerの再構築で表現する
- hooksはフォーカス、入力、スクロールなどのUI固有状態に必要な場合だけ使用し、不要になった画面は`HookConsumerWidget`から`ConsumerWidget`へ変更する
- Notifierは公開するStateに関係するUseCaseの実行順序、再試行、古いリクエスト結果の破棄、作成・更新・削除後の状態反映を担当し、Stateから独立した単発取得を集約しない
- Viewは状態の描画、入力、Notifierへの操作通知、Dialog・Snackbar・画面遷移の実表示を担当する
- Notifierの単体テストは仕様上重要な状態遷移、UseCaseの実行順序、競合、失敗後の復旧を検証し、`family`や`autoDispose`などRiverpod自体が保証する一般的な挙動を各Notifierで重複して検証しない
- ViewのWidgetテストは状態に応じた表示、操作可否、ユーザー操作の通知、Dialog・Snackbarの実表示を中心にする

#### 2. MemberManagementの一覧と更新後の整合性をNotifierへ分離する

- `MemberManagementState`には管理対象メンバーと本人メンバーを統合した一覧を保持し、操作中状態はViewで操作無効化や進捗表示に使用する場合だけ追加する
- 一覧取得、本人メンバーの解決、メンバーの作成・更新・削除と各処理後の一覧再取得をNotifierへ移す
- 招待コード生成は一覧Stateから独立した単発操作としてNotifierへ移さず、既存UseCaseの操作結果をViewで受け取り、招待Dialog、共有、Snackbarを実表示する
- 一覧取得、本人メンバーの解決、各更新処理、更新後の再取得はNotifier単体テスト、招待コード生成の成功・失敗とDialog・共有・SnackbarはUseCase単体テストとWidgetテストで検証する

#### 3. TripManagementのデータ状態をNotifierへ分離する

- `TripManagementState`と`TripManagementNotifier`を作成し、対象年の旅行一覧、グループメンバー、取得元ごとの読み込み・再試行状態を管理する
- 旅行一覧とグループメンバーの並行取得、旅行の作成・更新・削除後の一覧反映をNotifierへ移し、旅行IDを引数にした旅行詳細の単発取得は`TripManagement`のDialog表示処理から既存UseCaseを直接実行する
- 一覧とグループメンバーの部分失敗を区別し、成功した取得結果を維持して個別に再試行できる状態だけを保持する
- Androidウィジェットから渡された旅行IDも同じDialog表示処理で取得し、初期Dialogを一度だけ表示する制御はUI固有状態として`TripManagement`へ残す
- 更新処理の結果はStateへ蓄積せずNotifierの戻り値または例外として呼び出し元へ返し、旅行編集・削除DialogとSnackbarの実表示は`TripManagement`へ残す
- 並行取得の部分失敗、旅行の各更新処理、更新後の再取得はNotifier単体テスト、旅行詳細の取得成功・存在しない旅行ID・取得失敗とDialogの重複表示防止はWidgetテストで検証する

#### 4. DvcPointCalculationScreenの計算状態をNotifierへ分離する

- `DvcPointCalculationState`と`DvcPointCalculationNotifier`を作成し、グループ、契約、期間限定ポイント、利用ポイント、表示期間、計算結果と取得元ごとの読み込み・再試行状態を管理する
- グループと各ポイントデータの並行取得、表示期間変更時の再計算、契約・期間限定ポイント・利用ポイントの保存または削除後の再取得をNotifierへ移す
- データ取得と再計算を分離し、取得済みデータから表示期間だけを変更した場合は不要な再取得を行わない
- `DvcPointCalculationScreen`には期間入力、各登録・詳細Dialog、計算結果の表、Snackbarの実表示を残す
- 保存・削除の単発結果とエラーメッセージはStateへ保持せず呼び出し元へ返し、操作中状態は対象操作の無効化や進捗表示に使用する場合だけ保持する
- 並行取得、表示期間変更、保存・削除、再取得失敗時に既存データを維持する状態遷移を単体テストで検証する

#### 5. SettingsのAndroidウィジェット設定を機能別Providerへ分離する

- 画面全体を表す`SettingsState`と`SettingsNotifier`は作成せず、更新間隔と対象グループを独立した設定機能として扱う
- 更新間隔の取得は`Settings`のファイル上部に置くProviderで扱い、保存中の操作無効化と失敗時の値復元が必要な場合だけ機能単位のNotifierを使用する
- 対象グループ候補と選択中IDは引数のメンバーごとに取得状態を管理し、選択・解除後に同じProviderへ結果を反映する
- `Settings`には設定項目の描画と更新結果を知らせるSnackbarの実表示を残す
- 各設定の初期取得、保存、解除、失敗時の表示値維持と再試行を機能単位で検証する

#### 6. AccountSettingsの再認証と更新再試行を共通化する

- 画面共有状態がないため`AccountSettingsState`と`AccountSettingsNotifier`は作成しない
- 文字列照合で認証期限切れを判定する処理を型付きのApplication例外へ置き換える
- メール変更、パスワード変更、アカウント削除で重複している、認証期限切れの検出、再認証Modal表示、成功後の一度だけの再試行をPresentation層の共通処理へ抽出する
- 入力Modal、再認証Modal、成功・失敗を知らせるSnackbarの実表示は`AccountSettings`へ残す
- 初回成功、再認証後の成功、再認証のキャンセル・失敗、再試行の失敗についてUseCaseの呼び出し回数と画面上の結果を検証する

#### 7. Androidウィジェット起動Notifierで遷移先を解決する

- `TopPageState`と`TopPageNotifier`は作成せず、既存のAndroidウィジェット起動Notifierを起動要求の処理単位として拡張する
- Androidウィジェットから受け取った旅行IDによる旅行取得、所属グループ一覧との照合、遷移先の解決、処理済みIDの消費を既存Notifierへ移す
- 既存Notifierは処理中状態と遷移要求または失敗結果を通知し、Drawerの制御、実際の画面遷移、失敗時のSnackbar表示は`TopPage`へ残す
- 初期URI読み込み中、対象旅行・グループの解決成功、存在しない旅行、取得失敗、同じ要求の重複処理防止を単体テストで検証する

#### 8. Timelineの行データ取得と更新通知を機能単位に整理する

- 読み取り専用の行データは既存の`FutureProvider.autoDispose.family`を維持し、旅行はグループID・年、グループイベントとDVCはグループID、メンバーイベントはメンバーIDを引数に取得状態を管理する
- グループイベント、DVC、メンバーイベントは各UseCaseの全期間取得契約に合わせて取得結果を年別に保持し、年ごとのセルから同一条件の全件取得を重複実行しない
- `GetGroupEventsUsecase`と`GetMemberEventsUsecase`が取得失敗を空リストへ変換する処理を廃止し、例外をProviderまで伝播させてデータなしと取得失敗を区別できるようにする
- 行Widget内で取得と更新が完結するProviderはprivateのまま同じファイルに置く。別ファイルの保存・削除処理から同じ取得結果を無効化する必要があるProviderだけを機能単位の公開Providerとして分離し、更新結果を同じデータを表示する行へ反映する
- 更新中も既存データを維持する必要がある機能や複数の更新状態を描画する機能だけNotifierを使用し、複数機能へ更新を通知する必要がある場合だけ既存のMutationCoordinatorを使用する
- 行Widgetには受け取った状態の描画、編集Dialog、保存・削除結果のSnackbar表示を残す
- 引数ごとの状態分離、全期間取得の重複防止、保存・削除後の再取得、取得失敗からの再試行を検証し、Provider破棄そのものの一般的な挙動を機能ごとに重複して検証しない

- 大規模なViewを責務単位に分割する
  - 500行を超えるPresentation層の画面・編集UIを対象に責務を確認し、状態制御、フォーム、一覧、ダイアログなどの単位へ分割する

## 不具合修正
