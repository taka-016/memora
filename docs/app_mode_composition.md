# アプリモードと依存構成

## 起動時の判定

`AppCompositionRoot.fromBuildConfiguration`が`AppModeBuildConfiguration`でビルド指定を解析し、`AppModeResolver`で`AppMode`を決定する。`auto`と未指定はオンラインとして扱う。Factoryはビルド指定を解析せず、判定済みのモードを参照する。

判定結果を読み取り専用の`appModeProvider`へ注入する。認証、保存先、場所検索を個別に変更するProviderは持たない。Providerのoverrideは起動時の注入とテストで使用する。

`main.dart`はComposition Rootの起動処理を呼び出し、SDKの初期化を行わない。Application層のUseCaseはコンストラクタでインターフェースを受け取る。UseCaseを組み立てるProviderは`lib/composition_root/providers/`に置く。

## 実装の選択

| 対象 | オンライン | オフライン |
| --- | --- | --- |
| Repository・QueryService・Transaction | 既存のFirestore実装 | SQLite接続前のため共通の利用不可例外 |
| 認証・現在利用者 | Firebase Authを使う既存の認証導線 | 認証サービスを生成しない。端末内利用者の復元は後続対応 |
| 時刻 | `NtpSynchronizedAppClock`。同期失敗時は端末時刻を使用 | `SystemAppClock`。同期操作で外部通信しない |
| ログ | Crashlytics。debugでは端末にも出力 | debugのみ端末へ出力。profile・releaseでは保存・送信しない |
| 地図 | `GoogleMapViewBuilder` | 共通モデルの利用不可理由を表示 |
| 場所検索・周辺の場所名・現在地 | Places SDK・Geolocatorの既存実装 | 呼び出すと`FeatureUnavailableException`を返す |
| Androidウィジェットの端末連携 | HomeWidget・SharedPreferences・MethodChannel | 同じ端末連携。SQLiteからの更新は後続対応 |

`AppCapabilities`と`FeatureAvailability`が利用可能な機能と利用できない理由を表す。Presentation層はこのモデルを参照し、ビルド指定やDB種別を判定しない。地図はComposition Rootで選択した`MapViewBuilder`を画面へ渡す。テストでは必要に応じて`PlaceholderMapViewBuilder`を注入する。

現在のオフライン起動では、端末内保存が未実装である理由を表示する。認証画面や業務データのProviderは構築しない。SQLite・端末内利用者が未実装の状態で、FirestoreやFirebase Authに切り替えて処理を継続することはない。

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

モードの端末保存、Kotlin側のモード復元、オフライン時のネットワーク制約解除、SQLiteからのキャッシュ更新はTODO 7で接続する。現在はビルド指定から同じモードを判定し、オフラインのデータ取得要求は利用不可となる。

## 後続の接続

- TODO 5で認証操作と現在利用者の解決を分離し、端末内利用者と起動・ルーティングを接続する。オンライン専用機能の入口や直接呼び出しの制御もここで行う。
- TODO 6でSQLite実装を各Factoryのオフライン分岐へ接続する。接続後は端末内保存の利用可能状態と起動画面の判定を更新する。
- TODO 7で通常更新・操作コールバック・Kotlinフォールバックを両モードで使用可能にする。
- モード間のデータ共有・同期・移行は実装しない。

## 検証

- アーキテクチャテストでPresentation、Domain、Applicationの依存方向と起動・ウィジェット・CoreのSDK境界を確認する。
- Composition Rootのテストでビルド指定の判定結果、時計の注入、オフラインFactoryの利用不可結果、認証を解決しない準備中画面、地図の選択を確認する。
- `./check.sh`と`./check.sh --dart-define=MEMORA_APP_MODE=offline`で両方のビルド指定を検証する。
- Androidの`./gradlew :app:processDebugMainManifest`でマージ後のManifestから`FirebaseInitProvider`が除去され、自動収集がfalseであることを確認する。
- オフラインの通常利用・SQLite・実機での通信検証はTODO 5以降の実装と検証で完了させる。
