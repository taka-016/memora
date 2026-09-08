# ToDo List

## オフライン・オンラインモード対応

### 4. FactoryとComposition Rootでモードに応じた実装を選択する

- Firebase、Firestore、Crashlytics、NTP、Places SDK、地図SDK、位置情報、ネットワーク状態取得の具象型を使用している箇所を洗い出す
- 既存の`AppMode`、`AppModeResolver`、`AppModeBuildConfiguration`を使用し、起動時の判定結果をComposition Rootと各Factoryへ接続する
- ビルド指定の解析とモード判定の責務分離を維持し、Factoryは判定済みの`AppMode`だけを参照する。`auto`と未指定は現在のオンライン判定を維持する
- 現在のRepository、QueryService、Transaction、AuthServiceのFactoryパターンを維持し、各Factoryが同じ`AppMode`から対応する実装を生成するように変更する
- `AuthType`、`DatabaseType`、`LocationSearchApiType`の独立した可変StateProviderを廃止し、認証、保存先、場所検索が異なるモードを選択する不整合を防ぐ
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
- 既存のPresentation層の依存方向を検証するアーキテクチャテストを維持し、Domain層とApplication層が外側の層へ依存しないことの検証を追加する

### 5. オフラインモードの現在利用者と利用可能機能を実装する

- 認証操作と現在利用者の解決を別の責務に分離し、オフラインモードにサインイン、メール確認、再認証などのダミー実装を要求しない
- オフラインモードの初回起動時に端末内の利用者IDと本人メンバーを作成し、以降は同じ利用者として復元する
- オフラインモードはログイン画面とアカウント設定を経由せずに起動し、オンラインモードは既存の認証導線を維持する
- `AppRedirectController`、`CurrentMemberNotifier`、`TopPage`の認証状態に依存する制御を見直し、オフラインでも現在利用者の復元、年表の初期取得、Androidウィジェットからの画面遷移を行えるようにする
- オフラインモードではログアウト操作を表示せず、現在利用者の取得失敗時はログアウトや再ログインへ誘導せずに再試行できるようにする
- 地図、地図を前提とする訪問場所管理、場所検索、現在地、共有、招待の入口と操作をオフラインモードでは非表示にする
- 旅行編集内の訪問場所管理と旅程編集内の場所選択も非表示にし、対象画面の構築時にオンライン専用のProviderや外部サービスを解決しない
- Deep Link、Androidウィジェット、UI以外から利用対象外のオンライン機能が呼ばれた場合は、外部サービスへ接続せず共通の利用不可結果と案内を返す
- 設定画面で利用中のモード、保存先、利用可能機能、データ消失条件を確認できるようにする

### 6. Android内部SQLite DBとデータアクセスを実装する

- `group_members`の既存データに保存されている`orderIndex`をER図へ追記する
- Context7で公式ドキュメントを確認してからDriftと必要な関連パッケージを追加する
- ER図、Domain Entity、DTO、現在のFirestore Mapperを基準に、オフラインモードで使用する業務データのSQLiteスキーマを定義する
- SQLiteスキーマに`passportNumber`と`passportExpiration`を含めず、SQLiteファイルにはアプリ独自の暗号化を適用しない
- オフラインモードで使用しない`member_invitations`と`locations`はSQLiteのテーブル、Mapper、Repository、QueryServiceを作成しない
- オフライン時の旅行の場所一覧は空配列、旅程の`locationId`とDTOの場所情報はnullとして扱い、場所テーブルがなくても旅行・旅程を取得・保存できるようにする
- 場所情報を含む保存要求やバックアップの復元入力を受けた場合の扱いを共通の利用不可結果・検証方針と整合させ、未保存の場所への参照や場所情報の黙示的な欠落を防ぐ
- 主キー、外部キー、必須値、一意性、削除時の扱い、検索・並び替えに必要なindexを明示する
- Androidのアプリ内部ストレージにSQLiteファイルを作成し、DBの初期化、終了、バージョン管理、マイグレーション方針を整備する
- 日時、真偽値、nullable項目を既存Entity・DTOと相互変換できる保存形式へ統一する
- メンバー、メンバーイベント、グループ、グループイベントのMapper、Repository、QueryServiceと、グループメンバーのMapperを実装する
- グループメンバーの保存・更新・削除は既存の`GroupRepository`、グループと所属メンバーの取得は既存の`GroupQueryService`の責務を維持し、個別のRepositoryやQueryServiceは追加しない
- 旅行、タスク、旅程項目のMapperとQueryServiceを実装し、保存・更新・削除は既存の`TripEntryRepository`の集約単位を維持して実装する。タスクと旅程項目の個別Repositoryは追加しない
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
- 現在SharedPreferencesに保存しているウィジェット更新間隔などから復元対象の設定を特定し、業務データ・端末内利用者と原子的に復元できる保存方針を定める。SQLite外の設定更新をDBトランザクションだけで保護できる前提にしない
- バックアップファイルは利用者が入力したパスワードから導出した鍵で認証付き暗号化し、パスワードと復号鍵を端末へ保存しない
- Androidのシステムファイル選択画面を使用し、利用者が保存先と復元元を明示的に選択できるようにする
- 復元前にバックアップの形式、バージョン、完全性、パスワードを検証し、現在のオフラインデータを全件置換することへの確認を求める
- 復元は単一トランザクションで行い、検証または書き込みに失敗した場合は既存データを維持する
- 復元中はアプリ内の更新操作とバックグラウンドisolateのDBアクセス・ウィジェット更新を排他制御し、復元途中のデータや復元前の取得結果でキャッシュが更新されないようにする
- 復元後は現在利用者と各画面のProviderを再取得し、ウィジェットの対象グループ・選択日を検証してキャッシュを再生成する。復元した更新間隔で通常・フォールバックの定期更新を再登録する
- バックアップのパスワードを忘れた場合は復元できないことと、バックアップ未作成時はアプリ削除・データ消去・端末故障から復元できないことをバックアップ画面と設定画面で案内する

### 9. 両方のモードを検証して関連資料を更新する

- SQLiteの保存、取得、更新、削除、並び替え、関連データ取得、制約、ロールバック、DB再オープン、スキーママイグレーションをテストする
- アプリ側で削除済みのパスポート情報が画面・モデル・Firestoreへの書き込みに再導入されず、SQLiteにも保存されないことを確認する
- 既存Firestoreに残る`passportNumber`と`passportExpiration`を削除する移行スクリプトを作成し、dry-runで対象を確認でき、applyで他のフィールドを変更せず安全に削除できることをテストする
- 手動バックアップについて、往復復元、誤ったパスワード、改ざん、未対応バージョン、破損、復元失敗時のデータ・設定の維持、同時更新との排他、復元後の画面・ウィジェットの整合性をテストする
- オフラインモードで認証サービスを使用せずに起動・現在利用者の復元・取得失敗からの再試行ができ、場所情報なしで旅行・旅程を編集できることと、場所付き入力の扱いをテストする
- Auto Backupと端末間転送の対象にSQLite、設定、Androidウィジェットキャッシュが含まれないことを、対象Androidバージョンのバックアップルールと復元試験で確認する
- Repository、QueryService、Transaction、AuthServiceなどの全Factoryが同じ`AppMode`を参照し、モード間で実装の組み合わせが混在しないことを確認する
- `MEMORA_APP_MODE`の`online`、`offline`、`auto`、未指定、不明値について既存の解析・モード判定テストを維持し、判定結果が実際の初期化・実装選択へ反映されることを検証する
- オンラインモードの通常・フォールバックウィジェット更新は接続済みネットワークを要求し、オフラインモードの両更新経路は機内モードでも実行対象になることを確認する
- `MEMORA_APP_MODE=offline`を指定したrelease APKで、新規起動、再起動、機内モード、端末再起動後に対象機能とAndroidウィジェットを利用できることを確認する
- オフラインモードでFirebase、Firestore、Crashlytics、NTP、Places SDK、地図SDKが初期化されず、外部通信とオンライン機能の呼び出しが発生しないことを確認する
- `MEMORA_APP_MODE=online`を指定したrelease APKで、既存のFirestore保存、認証、共有、招待、地図、Androidウィジェットの振る舞いが維持されることを確認する
- 同じapplication IDと署名を使用した単一アプリとして、モード強制値ごとのrelease APKを作成できることを確認する
- モード指定に対応済みの`./check.sh`と`./tools/ci/release_android_apk.sh`および既存の引数検証テストを維持し、両モードの実装を接続した状態で継続的に検証・ビルドする
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

### Riverpodコード生成を効果の高いProviderへ導入する

Riverpodの手書きProviderと生成Providerは併用し、既存Providerの全面移行や手書きProviderの廃止を目標にしない。複数引数を持つfamily Provider、生成により宣言と引数管理を単純化できるNotifier、legacy Providerを優先対象とする。

Composition RootのRepository、QueryService、UseCase、外部Serviceなど、型を返すだけの単純な依存注入Providerは手書きを維持する。認証、現在利用者、Androidウィジェット起動、ルーターなど、アプリ全体のライフサイクルに関わるProviderも、関連機能の変更でコード生成の具体的な利点が生じるまでは移行しない。

Providerを移行するPRは既存のProvider名、公開範囲、ライフサイクル、retry、overrideの振る舞いを維持し、`./check.sh`が成功する、単独でマージ・リリース可能な状態で完結させる。

`AuthType`、`DatabaseType`、`LocationSearchApiType`の`StateProvider`はコード生成へ移行せず、「FactoryとComposition Rootでモードに応じた実装を選択する」の対応で`AppMode`による実装選択へ置き換える。

残る既存Providerは、関連する機能追加・修正・リファクタリングで対象ファイルを変更するときに、コード生成で宣言、family引数、ライフサイクル管理が明確に単純化できる場合だけ移行する。コード生成へ移行することだけを目的としたPRは追加しない。

## 不具合修正
