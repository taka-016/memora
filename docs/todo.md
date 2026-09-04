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

### Riverpod Provider定義をコード生成へ段階的に移行する

以下は番号ごとに1つのPRとして対応する。各PRは既存のProvider名、公開範囲、ライフサイクル、retry、overrideの振る舞いを維持し、`./check.sh`が成功する、単独でマージ・リリース可能な状態で完結させる。原則として前番号のPRがマージされてから次へ進み、生成Providerから手書きProviderへ依存しないよう、依存を持たないProviderから依存グラフをたどって移行する。

2以降のComposition Rootに関係するPRは、「FactoryとComposition Rootでモードに応じた実装を選択する」の対応でProvider配置が確定し、`AuthType`、`DatabaseType`、`LocationSearchApiType`の可変`StateProvider`が`AppMode`による実装選択へ置き換えられてから着手する。Application層のUseCaseファイルへRiverpodアノテーションは追加しない。

#### 1. コード生成基盤と依存を持たない代表Providerを移行する

- Context7でRiverpod 3系の公式ドキュメントと互換バージョンを確認し、`riverpod_annotation`をdependencies、`riverpod_generator`をdev_dependenciesへ追加する
- 生成ファイルを既存の`app_routes.g.dart`と同様にリポジトリへ含め、`./check.sh`のBuild runnerで生成漏れや競合を検出できる状態にする
- コード生成ではauto disposeがデフォルトになること、既存の常時保持Providerには`@Riverpod(keepAlive: true)`を指定すること、既存のretry設定を維持することを移行規約へ明記する
- `appTestEnvironmentProvider`、`appInitialLocationProvider`、`timelineRowsRefreshProvider`、`editStateNotifierProvider`を移行する
- 保持・破棄・再生成とoverrideの既存テストが移行前と同じ振る舞いを保証することを確認する

#### 2. Composition Rootの基盤Providerを移行する

- Composition Rootへ配置されたAppMode、外部SDKインスタンス、Clock、Transactionなど、他のProviderへ依存しない、または基盤Providerだけへ依存するProviderを移行する
- 依存注入Providerには原則`keepAlive: true`を指定し、同一`ProviderContainer`内のインスタンス共有とテストoverrideを維持する
- Domain層とApplication層がRiverpodおよび生成コードへ依存していないことをアーキテクチャテストで確認する

#### 3. 認証・位置情報・AndroidウィジェットのService Providerを移行する

- AuthService、現在地取得、場所検索、周辺地点名取得、Androidウィジェット用Storage・通知・起動URI取得のProviderを移行する
- オンライン・オフライン両モードで同じProvider名から適切な具象実装が注入され、利用対象外の外部SDKが初期化されないことを確認する

#### 4. グループ・メンバーのデータアクセスProviderを移行する

- グループ、グループイベント、メンバー、メンバーイベント、メンバー招待のRepositoryとQueryService Providerを移行する
- オンライン・オフライン両モードの取得・保存とProvider overrideが移行前と一致することを確認する

#### 5. 旅行・場所のデータアクセスProviderを移行する

- 旅行のRepositoryと、旅行、タスク、旅程項目、場所、地図表示用旅行取得のQueryService Providerを移行する
- オンライン・オフライン両モードの取得・保存とProvider overrideが移行前と一致することを確認する

#### 6. DVCポイントのデータアクセスProviderを移行する

- DVCポイント契約、期間限定ポイント、利用履歴のRepositoryとQueryService Providerを移行する
- オンライン・オフライン両モードの取得・保存とProvider overrideが移行前と一致することを確認する

#### 7. アカウントUseCase Providerを移行する

- ログイン、登録、ログアウト、認証状態監視、利用者取得、メール・パスワード更新、再認証、削除、トークン検証のUseCase ProviderをComposition Rootで移行する
- Provider名と認証エラー・再認証要求の伝播を維持する

#### 8. メンバーUseCase Providerを移行する

- メンバーの取得・作成・更新・削除、招待、アカウント紐付け、学年・厄年計算のUseCase ProviderをComposition Rootで移行する
- メンバーと招待に関係するRepositoryの組み合わせ、Transaction、Provider overrideを維持する

#### 9. グループUseCase Providerを移行する

- グループとグループイベントの取得・作成・更新・削除のUseCase ProviderをComposition Rootで移行する
- メンバーを含むグループ取得、Transaction、Provider overrideを維持する

#### 10. 旅行・場所UseCase Providerを移行する

- 旅行の取得・作成・更新・削除、タスク・旅程項目・場所取得、現在地・場所検索・周辺地点名取得のUseCase ProviderをComposition Rootで移行する
- 通常表示用と地図表示用の旅行取得Providerを区別し、QueryServiceの選択とProvider overrideを維持する

#### 11. DVCポイントUseCase Providerを移行する

- DVCポイント契約、期間限定ポイント、利用履歴の取得・保存・削除UseCase ProviderをComposition Rootで移行する
- WriteTransactionを使用する更新単位とProvider overrideを維持する

#### 12. AndroidウィジェットUseCase Providerを移行する

- ウィジェット表示対象、旅程キャッシュ、更新間隔、起動URI監視、定期更新登録のUseCase ProviderをComposition Rootで移行する
- 通常起動とバックグラウンドisolateで同じAppModeの依存が解決されることを確認する

#### 13. 年表のデータ取得Providerを移行する

- 旅行、DVCポイント利用、グループイベント、メンバーイベントの非同期Providerを移行する
- 複数の検索条件は専用family引数クラスから型付きの位置・名前付き引数へ置き換え、引数ごとのキャッシュ分離をテストする
- 自動再試行を無効にしているProvider向けの共通retry関数を定義し、失敗時の再試行回数を維持する

#### 14. 地図のNotifierを移行する

- `coordinateProvider`と`mapNotifierProvider`を移行する
- 座標状態の保持、family引数ごとの地図状態、場所検索と旅行取得のProvider overrideを維持する

#### 15. DVCポイント画面のNotifierとMutationCoordinatorを移行する

- `dvcPointCalculationNotifierProvider`と`dvcPointUsageMutationCoordinatorProvider`を移行する
- family引数、計算結果、排他制御、更新後の再取得と年表Providerのinvalidateを維持する

#### 16. グループ管理Notifierを移行する

- `groupManagementNotifierProvider`を移行し、コンストラクタ引数を生成クラスの`build`引数へ移す
- 部分成功、排他制御、refresh、`ref.keepAlive()`による進行中操作の保護を維持する

#### 17. メンバー管理Notifierを移行する

- `memberManagementNotifierProvider`を移行し、コンストラクタ引数を生成クラスの`build`引数へ移す
- 部分成功、排他制御、refresh、`ref.keepAlive()`による進行中操作の保護を維持する

#### 18. 旅行管理NotifierとMutationCoordinatorを移行する

- `tripManagementNotifierProvider`と`tripEntryMutationCoordinatorProvider`を移行する
- `copiedTaskTripIdProvider`を生成Notifierへ置き換え、単純な値の読み書きと画面離脱時の破棄を維持する
- 旅行更新後の再取得と年表Providerのinvalidateを維持する

#### 19. 設定画面のNotifierを移行する

- Androidウィジェットの更新間隔と表示対象グループを管理するNotifier Providerを移行する
- family引数、retry無効化、設定保存、ウィジェット再登録、画面再表示時の再取得を維持する

#### 20. 認証Notifierを移行する

- `authNotifierProvider`を`keepAlive: true`の生成Providerへ移行する
- 起動時の認証状態監視、ログイン、登録、ログアウト、メール確認、再認証、アカウント削除を既存テストで検証する

#### 21. 現在利用者Notifierを移行する

- `currentMemberNotifierProvider`を`keepAlive: true`の生成Providerへ移行する
- 認証Providerのlisten、ログイン・ログアウト時の現在利用者更新、再取得、エラー状態を維持する

#### 22. グループ年表の選択・更新Notifierを移行する

- `groupTimelineGroupSelectionNotifierProvider`と`groupTimelineRefreshNotifierProvider`を移行する
- グループ選択、Provider間のlisten、更新順序、Pull to Refresh、年表データのinvalidateを維持する

#### 23. Androidウィジェット起動Notifierを移行する

- `androidWidgetLaunchNotifierProvider`を`keepAlive: true`の生成Providerへ移行する
- Deep Linkの監視、起動時処理、再試行、対象旅行・グループの解決、破棄後の非同期完了を既存テストで検証する

#### 24. ルーターProviderを移行する

- `appRouterConfigProvider`を`keepAlive: true`の生成Providerへ移行する
- 認証状態変更時のredirect、ログアウト時の状態リセット、Androidウィジェットからの遷移、テストoverrideを統合テストで検証する

#### 25. Riverpodコード生成への移行を完了する

- `lib`配下に手書きの`Provider`、`FutureProvider`、`StreamProvider`、`NotifierProvider`、`AsyncNotifierProvider`、`StateProvider`定義と`flutter_riverpod/legacy.dart`のimportが残っていないことを確認する
- `riverpod_lint`と`custom_lint`のRiverpod 3系との互換性をContext7で確認して導入し、生成Providerから手書きProviderへの依存とfamily引数の同一性不備を静的解析で検出する
- `./check.sh`で`dart run custom_lint`を実行し、Riverpod固有のlint違反をCIとローカルの共通検証へ含める
- 手書きProvider定義の新規追加を検出するアーキテクチャテストを追加し、明示的な例外だけを許可する
- 未使用になったfamily引数クラス、import、共通ヘルパーを削除し、生成Provider名、keepAlive、retry、dependenciesの指定を全体で統一する
- `./check.sh`を実行し、生成差分が残らず、全モード共通の解析とテストが成功することを確認する

## 不具合修正
