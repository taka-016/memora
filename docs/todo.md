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

### Googleカレンダー連携のGoogle Cloud設定（ストーリー25・オンラインのみ）

[READMEの事前設定](../README.md#googleカレンダー連携の事前設定)に従い、以下を手動で実施する。

1. memora用のGoogle CloudプロジェクトでGoogle Calendar APIを有効にし、OAuth同意画面とAndroid用OAuthクライアントを設定する。利用するAPKの署名証明書を登録し、開発中に連携するGoogleアカウントをテストユーザーへ追加する。
2. カレンダー参照用のスコープとして`https://www.googleapis.com/auth/calendar.calendarlist.readonly`と`https://www.googleapis.com/auth/calendar.events.readonly`を登録する。Webアプリケーション用OAuthクライアントも用意し、その項目を含む最新の`android/app/google-services.json`へ更新する。
3. [READMEの公開手順](../README.md#紹介ページポリシーの公開)に従って紹介ページ・プライバシーポリシー・利用規約をGitHub Pagesで公開し、サイトの所有確認とGoogle Auth Platformへの各URLの登録を行う。登録スコープに必要なOAuth審査・公開設定を完了する。

## デザイン

## 開発環境

- KGP未対応の外部プラグイン（home_widget、workmanager_android）がbuilt-in Kotlin対応版に更新されたら対応する

## 全体

### `com.example`から正式なアプリ識別子への変更

着手前に「検討保留」の[識別子と既存インストールの扱い](#アプリ識別子と既存インストールの扱い)を確定する。オンライン・オフラインの別アプリ構成を維持し、オフライン版へFirebase・Google APIの設定や連携機能を追加しない。

1. 下表に従い、新しいオンライン版の識別子に対応するFirebase・Google Cloudのアプリ登録と認証設定を用意する。同じプロジェクトのAuthentication・Firestoreデータを引き続き使い、プロジェクトや既存データを作り直さない。
2. `android/app/build.gradle.kts`の`applicationId`・`namespace`と、`android/app/src/main/kotlin/com/example/memora/`配下のパッケージ宣言・配置を新しい名前へ変更する。オフライン版の`.offline`サフィックスを維持する。`packages/memora_android_widget_toast/`のAndroid namespace・Kotlinパッケージ・配置・`pubspec.yaml`のプラグイン登録も合わせる。
3. `home_widget_android_widget_cache_storage.dart`・`home_widget_calendar_cache_storage.dart`のReceiver完全修飾名、Androidウィジェットのaction名とManifestのintent-filterを更新する。関連する固定文字列・ソースファイルパスの参照も新しい名前にそろえる。
4. 新しいFirebase Androidアプリに対応する`android/app/google-services.json`を取得し、FlutterFire設定を再生成して`lib/firebase_options.dart`・ローカルの`firebase.json`を新しいFirebase App IDへ合わせる。Web OAuthクライアントの項目を維持し、Git管理対象外の設定ファイルを強制追加しない。
5. iOS・macOSの`Runner.xcodeproj/project.pbxproj`にあるRunner/RunnerTestsのBundle ID、macOSの`Runner/Configs/AppInfo.xcconfig`、Linuxの`CMakeLists.txt`の`APPLICATION_ID`、macOS・Windowsの`com.example`名義の著作権・CompanyNameを正式な識別子・公開者表記へ変更する。未対応プラットフォームの新規対応は含めない。
6. READMEのOAuth設定・ADB操作のapplication IDと、識別子を記載している導入・配布手順を更新する。Google Play等で配布済みの場合は、下表の別アプリ扱いに合わせて配布先も用意する。

変更に合わせて扱う外部設定は以下とする。現時点ではConsole上の登録状況・公開状況は未確認。

| 対象 | 変更時に行うこと |
| --- | --- |
| Firebase Console | 既存Androidアプリのパッケージ名は変更できないため、同じプロジェクトへ新しいオンライン版のAndroidアプリを追加し、利用する署名証明書を登録する。Firebase App IDが変わるため設定ファイルも更新する。[公式手順](https://firebase.google.com/docs/android/setup) |
| Google CloudのAndroid OAuthクライアント | 新しいパッケージ名とdebug・releaseそれぞれの署名SHA-1の組でクライアントを用意する。Play App Signing利用時は配信APKのアプリ署名証明書を使う。Calendar API・読み取りスコープ・同意画面・Web OAuthクライアントは同じプロジェクトの設定を継続利用する。[クライアント設定](https://pub.dev/packages/google_sign_in_android) |
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
- **既存インストール**: application ID変更後はAndroid上で別アプリとなり、旧版のSQLite・端末設定・ログイン状態・Googleカレンダーの表示設定・ホーム画面ウィジェットは自動では引き継がれない。旧版の併存・削除時期と、必要なデータ引継ぎの範囲を決める。オフラインデータを残す場合は現行形式のバックアップの手動復元を候補とし、旧形式互換や自動移行を追加する前提にしない。

### TimeTreeのICSインポート

2026年10月25日に、作業環境の`timetree.ics`と現行の予定モデル・Firestore/SQLiteの保存処理を調査した。実DBの登録内容との照合は未実施。以下の対応案は未採用であり、実装指示ではない。元ファイルは調査時点でGit未追跡のため、リポジトリだけでは再解析できない。

#### 解析結果

| 項目 | 内容 |
| --- | --- |
| 予定数 | 1,862件（繰り返しの各回を展開する前） |
| 終日予定 | 498件（単日371件・複数日127件） |
| 時刻付き予定 | 1,364件（Asia/Tokyo 1,359件・Asia/Hong_Kong 1件・UTC 4件） |
| 繰り返し | 21件（終日19件・時刻付き2件）、うち17件は終了条件なし |
| 個別回の情報 | EXDATEが2件、RELATED-TOが2件。RECURRENCE-IDはなし |
| 補足情報 | 説明143件・場所150件・座標90件・URL25件 |
| 通知 | 1,476予定に計2,018件のVALARM |
| 欠落・重複・期間 | タイトル・開始・終了・UIDの欠落なし、UID重複なし、終了が開始より前の予定なし。開始と終了が同じ予定は84件 |


#### 現行DBへの対応と変換上の注意

- [ER図](er_diagram.md)の`calendar_events`へタイトル・開始終了日時・終日区分・繰り返しを、`calendar_labels`へ分類名と背景色を対応づけられる。説明・場所・座標・URL・通知・元UIDを保存する項目は現行の予定モデルにない。
- memoraのグループIDはファイルにないため、取り込み先を選ぶ必要がある。オンラインでグループの予定として保存すると、そのグループ内で共有される。分類名とメンバーの対応はファイルから確定できない。
- 終日のDTENDは終了日を含まない境界だが、memoraの終日終了日は表示対象に含まれる。現行仕様へ合わせる場合、終日498件の終了日から1日引く。時刻付きの終了日時は引かない。[RFC 5545 §3.6.1](https://www.rfc-editor.org/rfc/rfc5545.html#section-3.6.1)
- 終日は`VALUE=DATE`なしの日付8桁で出力されている。折り返し行571か所と、説明等のエスケープされた改行・文字を復元する必要がある。
- RRULEのうち5件に、現行パーサーで未対応のWKSTがある。今回の5件は年・月単位または週の間隔が1なので、発生日を維持してWKSTを除去する案がある。繰り返しをそのまま保存する場合も正規化・検証が必要。
- 終日の系列2件で、EXDATEが日付ではなくUTC日時で出力されているため、終日の個別回を示す日付への正規化が必要。
- 系列の特定回をEXDATEで除外し、RELATED-TOで参照する別予定に置き換えた例がある。取消しと独立予定として残す案なら表示を維持できるが、後の系列編集には追従しない。RELATED-TOだけで変更前の回を一般的に一意特定できるとは限らない。[RFC 5545 §3.8.4.5](https://www.rfc-editor.org/rfc/rfc5545.html#section-3.8.4.5)
- 開始と終了が同じ84件は現行モデルで保持できる。分類なし2件のタイトルにはキャンセルの記載があるが、タイトルだけで取消しや取り込み除外を確定しない。
- アプリ内で解析・プレビューし、既存の登録処理を通す案は[ADR-003](adr/adr-003-app-only-data-registration.md)と整合する。Firestoreの既存保存処理は予定・個別回とラベルの利用件数を更新するため、DBへの単純な直接投入では同じ動作にならない。

#### 再開時に決めること

- **対応範囲**: 今回のTimeTree形式に限定するか、他サービスのICSも扱うか。オンライン・オフラインのどちらを対象とするか。全期間か期間指定か。繰り返しは系列として保持するか、指定期間の個別予定へ展開するか（17件は終了条件がないため無期限の全展開はできない）。
- **取り込み先とラベル**: 取り込み先グループ、既存ラベルとの対応、新規作成の可否、分類なし2件の扱い、ファイルにない文字色・並び順の補完方法を決める。
- **説明・場所・座標・URLの取り込み**: 予定への専用項目追加は[カレンダーの実装タスク](#2-予定の詳細項目urlメモ場所を追加する)として切り出した。ICSの各値を専用項目へどう対応づけるか、取り込めない値をどう扱うかを決める。
- **通知の取り込み**: ICSのVALARMを通知設定へどう対応づけるか、未対応の通知をどう扱うか、取り込み後に実際の通知を有効にするかを決め、取り込み前の案内内容も決める。
- **繰り返しの例外**: 除外日と関連予定を「取消し＋独立予定」として残すか、変更された個別回として統合するか。統合する場合の対応づけと、後の系列編集での扱いを決める。
- **再取り込み**: 一度限りか、登録済みをスキップするか、元データの変更も反映するか。対応を記録する場合は取り込み元・UID・グループと内部IDの保存方法を決める。更新も扱う場合はmemora側の編集・削除との優先関係を決める。現行の新規登録は内部IDを新しく発行するため、UIDを保持しなければ再取り込みで重複し得る。
- **途中失敗と再実行**: 予定単位の部分成功を許容するか、ファイル全体の取消しまで保証するか。部分成功後の再実行は重複を生む可能性がある。UIDの対応記録や再開処理は保存項目・通信・実装を増やし、全体取消しはさらに仕組みが必要になるため、保証範囲をユーザーが判断する。
- **元の作成・更新日時**: TimeTreeのCREATED・LAST-MODIFIEDを残すか。現行FirestoreのcreatedAt・updatedAtはmemoraでの保存時刻なので、元の履歴を残すなら別項目が必要になる。
- **取り込み前後の確認**: プレビューで確認する対象範囲・ラベル対応・変換内容・保存しない情報と、結果表示で確認する成功・失敗・スキップの件数および理由を決める。
