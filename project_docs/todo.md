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

## グループ年表画面

## 旅行管理画面

## マップピンボトムシート

## 招待機能

## グループイベント

## メンバーイベント

## カレンダー

## デザイン

## 開発環境

- KGP未対応の外部プラグイン（home_widget、workmanager_android）がbuilt-in Kotlin対応版に更新されたら対応する

## 全体

### `com.example`から正式なアプリ識別子への変更

着手前に「検討保留」の[識別子と既存インストールの扱い](#アプリ識別子と既存インストールの扱い)を確定する。オンライン・オフラインの別アプリ構成を維持し、オフライン版へFirebase・Google APIの設定や連携機能を追加しない。

1. 下表に従い、新しいオンライン版の識別子に対応するFirebase・Google Cloudのアプリ登録と認証設定を用意する。同じプロジェクトのAuthentication・Firestoreデータを引き続き使い、プロジェクトや既存データを作り直さない。
2. `android/app/build.gradle.kts`の`applicationId`・`namespace`と、`android/app/src/main/kotlin/com/example/memora/`配下のパッケージ宣言・配置を新しい名前へ変更する。オフライン版の`.offline`サフィックスを維持する。`packages/memora_android_widget_toast/`のAndroid namespace・Kotlinパッケージ・配置・`pubspec.yaml`のプラグイン登録も合わせる。
3. `home_widget_android_widget_cache_storage.dart`・`home_widget_calendar_cache_storage.dart`のReceiver完全修飾名、Androidウィジェットのaction名とManifestのintent-filterを更新する。関連する固定文字列・ソースファイルパスの参照も新しい名前にそろえる。
4. 新しいFirebase Androidアプリに対応する`android/app/google-services.json`を取得し、FlutterFire設定を再生成して`lib/firebase_options.dart`・ローカルの`firebase.json`を新しいFirebase App IDへ合わせる。利用中の認証設定を維持し、Git管理対象外の設定ファイルを強制追加しない。
5. iOS・macOSの`Runner.xcodeproj/project.pbxproj`にあるRunner/RunnerTestsのBundle ID、macOSの`Runner/Configs/AppInfo.xcconfig`、Linuxの`CMakeLists.txt`の`APPLICATION_ID`、macOS・Windowsの`com.example`名義の著作権・CompanyNameを正式な識別子・公開者表記へ変更する。未対応プラットフォームの新規対応は含めない。
6. READMEのFirebase設定・ADB操作のapplication IDと、識別子を記載している導入・配布手順を更新する。Google Play等で配布済みの場合は、下表の別アプリ扱いに合わせて配布先も用意する。

変更に合わせて扱う外部設定は以下とする。現時点ではConsole上の登録状況・公開状況は未確認。

| 対象 | 変更時に行うこと |
| --- | --- |
| Firebase Console | 既存Androidアプリのパッケージ名は変更できないため、同じプロジェクトへ新しいオンライン版のAndroidアプリを追加し、利用する署名証明書を登録する。Firebase App IDが変わるため設定ファイルも更新する。[公式手順](https://firebase.google.com/docs/android/setup) |
| Google CloudのAndroid OAuthクライアント | Googleログイン等で利用している場合、新しいパッケージ名とdebug・releaseそれぞれの署名SHA-1の組でクライアントを用意する。Play App Signing利用時は配信APKのアプリ署名証明書を使う。端末カレンダー連携のためのOAuth設定は不要。[署名証明書の確認](https://developers.google.com/android/guides/client-auth) |
| Maps・PlacesなどのAPIキー | Androidアプリ制限に新しいパッケージ名と署名SHA-1を登録する。旧版を併存させる間は旧設定の削除を急がず、既存のAPI制限を維持する。[制限の設定](https://developers.google.com/maps/api-security-best-practices) |
| Google Play（配布済みの場合） | application IDが変わると別アプリとなり、既存掲載への更新として配布できない。新規掲載・配布先を用意するか、既存IDを維持するかを実装前に判断する。[application IDの扱い](https://developer.android.com/build/configure-app-module) |
| Apple側の登録（利用済みの場合） | iOS・macOSのBundle ID変更に合わせ、Apple DeveloperのApp ID・署名プロファイル・利用中の外部サービスのアプリ登録を更新する。未登録のサービスをこの作業だけのために新規導入しない。 |

## リファクタリング

## 不具合修正

---

## 検討保留（実装タスクとは別枠・方針未決定）

この節は、実装できる粒度に達していない検討事項と調査結果の保管先とする。既存の実装タスクとは区別し、ユーザーが方針を決めるまで実装に着手しない。

### アプリ識別子と既存インストールの扱い

- **推奨候補（未決定）**: オンライン版を`io.github.taka016.memora`、オフライン版を`io.github.taka016.memora.offline`とする案。GitHub名`taka-016`からハイフンを除いて利用者名に由来する識別子とし、アプリの表示名とは分ける。利用先での識別子の重複は採用前に確認する。保有する独自ドメインがある場合は、その逆順を接頭辞にする案も比較する。
- **既存インストール**: application ID変更後はAndroid上で別アプリとなり、旧版のSQLite・端末設定・ログイン状態・端末カレンダーの表示設定・ホーム画面ウィジェットは自動では引き継がれない。旧版の併存・削除時期と、必要なデータ引継ぎの範囲を決める。オフラインデータを残す場合は現行形式のバックアップの手動復元を候補とし、旧形式互換や自動移行を追加する前提にしない。
