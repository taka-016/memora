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

#### 1. コード生成基盤と移行パターンを確立する

- Context7でRiverpod 3系の公式ドキュメントと互換バージョンを確認し、`riverpod_annotation`をdependencies、`riverpod_generator`をdev_dependenciesへ追加する
- 生成ファイルを既存の`app_routes.g.dart`と同様にリポジトリへ含め、`./check.sh`のBuild runnerで生成漏れや競合を検出できる状態にする
- コード生成ではauto disposeがデフォルトになることを移行規約へ明記し、既存の`Provider`と`NotifierProvider`は`@Riverpod(keepAlive: true)`、既存のauto dispose Providerは`@riverpod`を基本としてライフサイクルを維持する
- 自動再試行を無効にしているProviderは、既存の`retry: (_, _) => null`を`@Riverpod(retry: ...)`で維持する移行規約を定める
- Provider名と公開範囲を維持し、利用側の`ref.watch`、`ref.read`、`ref.invalidate`、`overrideWith`を不要に変更しない移行方針を定める
- 生成Providerから手書きProviderへ依存しないよう、依存を持たないProviderから依存グラフをたどって移行する規約を定める
- `appTestEnvironmentProvider`と`timelineRowsRefreshProvider`を常時保持する関数ベースProvider、`editStateNotifierProvider`をauto disposeするクラスベースNotifierの代表例として移行する
- 代表例について、保持・破棄・再生成とoverrideの既存テストが移行前と同じ振る舞いを保証することを確認する

#### 2. Composition Rootの依存注入Providerを移行する

- 「FactoryとComposition Rootでモードに応じた実装を選択する」の対応でProvider配置を確定してから着手し、Application層のUseCaseファイルへRiverpodアノテーションを追加しない
- Composition Rootへ集約した外部SDKインスタンス、設定値、Storage、Clockなど、他のProviderへ依存しない生成Providerから移行する
- Repository、QueryService、Transaction、外部Serviceの生成Providerを依存順に移行する
- UseCaseの生成ProviderをComposition Rootへ定義し、Domain層とApplication層がRiverpodおよび生成コードへ依存しない状態を維持する
- 依存注入Providerには原則`keepAlive: true`を指定し、同一`ProviderContainer`内のインスタンス共有とテストoverrideが移行前と一致することを確認する
- オンライン・オフライン両モードで同じProvider名から適切な具象実装が注入され、生成コードがモード固有実装への依存を内側の層へ持ち込まないことをアーキテクチャテストで確認する

#### 3. Presentation層の関数ベースProviderを移行する

- 年表の旅行、DVCポイント利用、グループイベント、メンバーイベント取得Providerを移行し、複数の検索条件は専用family引数クラスから型付きの位置・名前付き引数へ置き換える
- family引数にEntity、DTO、独自クラスを残す場合は、安定した`==`と`hashCode`を持つことをテストで保証する
- 自動再試行を無効にしている非同期Provider向けの共通retry関数を定義して指定し、失敗時の再試行回数が移行前と一致することを確認する
- `TripEntryMutationCoordinator`と`DvcPointUsageMutationCoordinator`の生成Providerを移行し、更新後にinvalidateするProviderと実行順序を維持する
- ルーティングと初期表示位置のProviderを移行し、アプリ全体で保持すべきProviderには`keepAlive: true`を指定する

#### 4. 画面単位で完結するNotifierを移行する

- 座標、地図、DVCポイント計算、グループ管理、メンバー管理、旅行管理、設定画面のNotifierを機能単位のPRに分けて移行する
- family Notifierのコンストラクタ引数を生成クラスの`build`引数へ移し、生成された引数プロパティと既存の状態初期化が一致することを確認する
- `ref.keepAlive()`で進行中の操作を保護しているNotifierは、一時保持リンクの開始・終了条件を維持する
- 各機能のProvider override、部分成功、排他制御、refresh、invalidate、破棄後の非同期完了を既存テストで検証する

#### 5. 複数画面とアプリライフサイクルに関わるNotifierを移行する

- グループ年表の選択・更新Notifierを移行し、Provider間のlisten、更新順序、Pull to Refresh後の再取得を維持する
- 認証、現在利用者、Androidウィジェット起動Notifierをこの順に個別PRで移行する
- 常時監視されるProviderには`keepAlive: true`を明示し、認証状態変更、ログアウト、Deep Link、バックグラウンド復帰時にProviderが意図せず破棄・再初期化されないことを確認する
- `main.dart`直下の監視とルーターredirectを含む統合テストで、起動から画面遷移までの状態連携を検証する

#### 6. legacy Providerを整理する

- `copiedTaskTripIdProvider`を生成Notifierへ移行し、単純な値の読み書きとauto disposeの要否を利用画面のライフサイクルに合わせて明示する
- `AuthType`、`DatabaseType`、`LocationSearchApiType`の可変`StateProvider`はコード生成へ移行せず、`AppMode`とComposition Rootによる一貫した実装選択へ置き換えて削除する
- `flutter_riverpod/legacy.dart`のimportと`StateProvider`、`StateNotifierProvider`、`ChangeNotifierProvider`が残っていないことを確認する

#### 7. 手書きProviderを廃止して移行を完了する

- `lib`配下に手書きの`Provider`、`FutureProvider`、`StreamProvider`、`NotifierProvider`、`AsyncNotifierProvider`定義が残っていないことを確認し、例外が必要な場合は理由と移行条件を文書化する
- `riverpod_lint`と`custom_lint`のRiverpod 3系との互換性をContext7で確認して導入し、生成Providerから手書きProviderへの依存とfamily引数の同一性不備を静的解析で検出する
- `./check.sh`で`dart run custom_lint`を実行し、Riverpod固有のlint違反をCIとローカルの共通検証へ含める
- 手書きProvider定義の新規追加を検出するアーキテクチャテストを追加し、明示的な例外だけを許可する
- 未使用になったfamily引数クラス、import、共通ヘルパーを削除し、生成Provider名、keepAlive、retry、dependenciesの指定を全体で統一する
- `./check.sh`を実行し、生成差分が残らず、全モード共通の解析とテストが成功することを確認する

## 不具合修正
