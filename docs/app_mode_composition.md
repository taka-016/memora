# アプリモードと依存構成

## 起動時の判定

`AppCompositionRoot.fromBuildConfiguration`が`AppModeBuildConfiguration`でビルド指定を解析し、`AppModeResolver`で`AppMode`を決定する。`auto`と未指定はオンラインとして扱う。Factoryはビルド指定を解析せず、判定済みのモードを参照する。

判定結果を読み取り専用の`appModeProvider`へ注入する。認証、保存先、場所検索を個別に変更するProviderは持たない。Providerのoverrideは起動時の注入とテストで使用する。

`main.dart`はComposition Rootの起動処理を呼び出し、SDKの初期化を行わない。Application層のUseCaseはコンストラクタでインターフェースを受け取る。UseCaseを組み立てるProviderは`lib/composition_root/providers/`に置き、アカウント・メンバー・グループ・旅行・場所・DVC・Androidウィジェット・アプリ共通へ機能単位でまとめる。SQLite接続の所有と破棄は同ディレクトリの`offlineDatabaseProvider`が担当する。場所のProviderには地図Builder、AndroidウィジェットのProviderには端末ストレージの注入先も含める。

## 実装の選択

| 対象 | オンライン | オフライン |
| --- | --- | --- |
| Repository・QueryService・Transaction | 既存のFirestore実装 | SQLite実装。招待・場所のデータアクセスは共通の利用不可例外 |
| 認証・現在利用者 | Firebase Authを使う既存の認証導線 | 認証サービスを生成・購読せず、端末内の利用者IDと本人情報を復元 |
| 時刻 | `NtpSynchronizedAppClock`。同期失敗時は端末時刻を使用 | `SystemAppClock`。同期操作で外部通信しない |
| ログ | Crashlytics。debugでは端末にも出力 | debugのみ端末へ出力。profile・releaseでは保存・送信しない |
| 地図 | `GoogleMapViewBuilder` | 共通モデルの利用不可理由を表示 |
| 場所検索・周辺の場所名・現在地 | Places SDK・Geolocatorの既存実装 | 呼び出すと`FeatureUnavailableException`を返す |
| Androidウィジェットの端末連携 | HomeWidget・SharedPreferences・MethodChannel。Firestoreで更新し、接続済みネットワークを要求 | 同じ端末連携。SQLiteで更新し、ネットワーク接続を要求しない |

`AppCapabilities`と`FeatureAvailability`が利用可能な機能と利用できない理由を表す。Presentation層はこのモデルを参照し、ビルド指定やDB種別を判定しない。地図はComposition Rootで選択した`MapViewBuilder`を画面へ渡す。テストでは必要に応じて`PlaceholderMapViewBuilder`を注入する。

オフライン起動では、`CurrentMemberResolver`を`SqliteCurrentMemberResolver`へ切り替える。内部の`LocalCurrentMemberResolver`がJSONの利用者ID・本人IDを復元し、SQLiteに本人が未登録の場合だけ同じIDで登録する。その後はSQLiteの本人情報を返して編集結果を反映する。初回に利用者IDと本人メンバーIDを生成し、アプリ内部の`offline_current_member.json`へバージョン付きでまとめて保存する。一時ファイルへの書き込みとrenameが成功してから本人を返す。破損や未対応バージョンは新しい利用者で上書きせず、取得エラーとして再試行を案内する。オンラインでは`AuthenticatedCurrentMemberResolver`が`CurrentUserService`とメンバーのQueryServiceを使用する。認証操作は`AuthService`の責務に残す。

ルーターと現在メンバーNotifierは、オフライン時に認証Notifierを購読しない。ログイン・新規登録・本人設定・アカウント設定のURLは画面構築前に年表へ誘導する。本人取得の失敗時はログアウトせず再試行でき、本人の復元後は年表の初期取得とAndroidウィジェットからの画面遷移へ進む。

地図・訪問場所管理・場所検索・現在地・共有・招待の入口を非表示にし、旅行・旅程編集では地図Builderを解決しない。地図への直接遷移は利用不可理由を表示する。招待や地図用データのUseCase解決も`AppCapabilities.requireAvailable`で外部依存の解決前に制限する。

業務データ取得・保存はSQLiteを使用し、端末内保存を利用可能にする。接続は初回アクセス時に初期化し、Providerの破棄時に閉じる。保存形式と集約単位のトランザクションは[オフラインDB設計](offline_database.md)を参照。

## 外部SDKの配置と初期化

- Firebase Core、Firestoreの設定、Crashlyticsの有効化は`OnlineAppServices.initialize`に集約する。オフライン側の初期化ではこれらを呼び出さない。
- Android Manifestでは`FirebaseInitProvider`をマージ対象から除去し、FirebaseとCrashlyticsの自動収集を無効にする。オンラインのComposition RootからCrashlyticsを明示的に有効化する。
- Apple向けの`Info.plist`でも自動収集を無効にする。現在のXcodeプロジェクトは`GoogleService-Info.plist`を同梱していない。FlutterFireは同ファイルを見つけるとプラグイン登録時にFirebaseを初期化するため、オフライン対応を維持する際は追加しない。Firebase設定は既存の`firebase_options.dart`から明示的に渡す。
- Crashlyticsへのログ送信と端末ログの出力は`lib/infrastructure/logging/`、NTPと端末時刻の具象実装は`lib/infrastructure/time/`に置く。Core層に外部SDKを参照させない。
- Google MapsのWidgetとBuilderは`lib/infrastructure/map_views/`に置く。SDKは選択されたWidgetが構築されると使用される。
- Places SDKは既存の`PlacesMethodChannelHandler`が検索時に初期化する。Dart側ではオンライン用のサービスだけがこのチャネルを呼ぶ。位置情報も選択されたGeolocator実装からだけ取得する。
- 独立したネットワーク状態取得サービスは存在しない。接続状態の指定はWorkManagerの制約にある。

Crashlyticsの自動収集を無効化する設定と実行時の有効化は、[Firebaseの公式手順](https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports#enable_opt-in_reporting)に従う。オフラインでは収集設定の変更のためにもFirebaseを初期化しない。

## Androidウィジェット

バックグラウンド更新と操作コールバックは`android_widget_composition_root.dart`を通じて共通UseCaseを組み立てる。QueryServiceは画面と同じFactoryとモードを使い、バックグラウンド用の取得ではエラーを上位に伝える設定を維持する。

業務制御の`AndroidWidgetBackgroundUpdateRunner`と`AndroidWidgetPeriodicUpdateRegistrar`はApplication層に残し、WorkManager・端末ストレージとの連携はInfrastructure層に置く。

解決済みのモードを端末へ保存し、通常更新・操作コールバック・Kotlinのフォールバック更新で現ビルドの解決済みモードと照合する。不一致、未保存、不明値の場合は更新依存を初期化しない。オンラインだけWorkManagerへ接続済みネットワークの制約を設定し、オフラインではSQLiteのQueryServiceと端末時刻を使用する。

ウィジェットキャッシュは1つだけ公開し、生成元モード、対象グループ、選択日、旅行・旅程を保持する。Kotlinは生成元モードと対象グループが現在値に一致するキャッシュだけを表示する。ファイルは一時ファイルへ書き終えてから固定パスへ置き換えるため、書き込み途中のJSONを公開しない。対象解除やモード変更ではキャッシュ参照と公開済みファイルを消去する。

更新の世代番号、操作トークン、更新処理全体の排他ロックは持たない。同じ対象への更新や操作が重なった場合は最後に完了した処理のキャッシュを採用するため、先に開始した処理が一時的に古いデータや選択日を戻す場合がある。対象変更と公開確認が同時に起きた場合も、対象と異なるキャッシュはKotlinが表示しない。キャッシュは再構築可能な派生データとして扱い、手動更新、保存後更新、次回の定期更新で復旧する。この許容範囲を超えて厳密な順序保証が必要になった場合は、キャッシュ側の世代管理を追加せず、更新要求を単一の実行主体へ直列化する設計を別途検討する。

旅行・旅程の取得失敗は空の取得結果と区別して上位へ伝え、既存キャッシュを維持する。正常に取得した空結果は手動更新では公開し、バックグラウンド更新では既存表示を維持する。

## 後続の接続

- モード間のデータ共有・同期・移行は実装しない。

## 検証

- アーキテクチャテストでPresentation、Domain、Applicationの依存方向と起動・ウィジェット・CoreのSDK境界を確認する。
- Composition Rootのテストでビルド指定の判定結果、時計の注入、オフラインFactoryのSQLite選択とオンライン専用機能の利用不可結果、認証を解決しない起動・直接遷移、地図の選択を確認する。
- `./check.sh`と`./check.sh --dart-define=MEMORA_APP_MODE=offline`で両方のビルド指定を検証する。
- Androidの`./gradlew :app:processDebugMainManifest`でマージ後のManifestから`FirebaseInitProvider`が除去され、自動収集がfalseであることを確認する。
- SQLiteの保存・復元・制約・ロールバックはDBテストで確認する。実機での通常利用と外部通信の検証はTODO 9で完了させる。
