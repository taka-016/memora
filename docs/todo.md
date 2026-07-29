# ToDo List

## オフライン版・オンライン版のビルド切り分け対応

### 1. 各ビルドの仕様をユーザーストーリーへ反映する

- オンライン版は現在のFirebase Auth、Firestore、地図、共有、招待機能を維持する
- オフライン版はユーザー登録やログインを不要とし、Android内部SQLite DBだけで業務データを管理する
- オフライン版では地図、共有、招待などのオンライン機能を利用できない
- オンライン版とオフライン版はビルド時に切り分ける
- アプリ内でオンライン版とオフライン版を切り替える機能は作成しない
- SQLiteとFirestoreの間でデータを同期・移行する機能は今回作成しない
- 有料化、Google Play Billing、オンライン利用権、無償オンライン利用の手動付与は今回の対応範囲から外す
- 実装着手前にユーザーストーリーの内容をレビューし、今回の対応範囲を確定する

### 2. ビルド時にオンライン版とオフライン版を切り替える

- オンライン版またはオフライン版を指定するビルドフラグを定義する
- ビルドフラグはコンパイル時に確定し、アプリの実行中には変更できないようにする
- オンライン版とオフライン版それぞれのビルドコマンドを整備する

### 3. 外部サービスへの依存をInfrastructure層へ集約する

- Firebase、Firestore、Crashlytics、NTP、Places SDK、ネットワーク状態取得の具象型を使用している箇所を洗い出す
- Application層とCore層には外部サービスを抽象化したインターフェースだけを配置し、具象実装をInfrastructure層へ配置する
- `main.dart`から個別SDKの初期化処理を除き、Composition Rootで選択したInfrastructure実装だけを初期化する
- Androidウィジェットのバックグラウンド更新と操作コールバックからFirestore具象実装への直接依存を除く
- ロガーからCrashlyticsへの直接依存を除き、オンライン版はCrashlytics、オフライン版は端末内またはno-opの実装を構成する
- アプリ時刻からNTPへの直接依存を除き、オンライン版はNTP、オフライン版は端末時刻の実装を構成する
- 地図関連サービスの利用可否と利用できない理由を表す状態をApplication層に定義する
- オフライン版では地図関連サービスを常に利用不可とし、オンライン版では既存の利用可否判定を使用する
- Application層とCore層から禁止対象の外部サービスパッケージをimportしていないことをアーキテクチャテストで確認する

### 4. Android内部SQLite DBを構築する

- `group_members`の既存データに保存されている`orderIndex`をER図へ追記する
- `orderIndex`の反映漏れ以外はER図のテーブル、項目、主キー、外部キー、関連を変更しない
- Firestoreの既存Collection・フィールド構造を変更せず、ER図と現在のFirestore Mapperを基準にSQLiteスキーマを定義する
- Context7で公式ドキュメントを確認してからDriftと必要な関連パッケージを追加する
- Android内部ストレージにSQLiteファイルを作成し、DBの初期化、終了、バージョン管理を行う
- Driftのスキーママイグレーション方針を整備する
- 日時、真偽値、nullable項目を既存Entity・DTOと相互変換できる保存形式へ統一する

### 5. SQLite用のデータアクセスを実装する

- メンバー、メンバーイベント、招待のMapper、Repository、QueryServiceを実装する
- グループ、グループメンバー、グループイベントのMapper、Repository、QueryServiceを実装する
- 旅行、訪問場所、タスク、旅程項目のMapper、Repository、QueryServiceを実装する
- DVCポイント契約、期間限定ポイント、利用履歴のMapper、Repository、QueryServiceを実装する
- 複数更新を原子的に保存できるSQLite用`WriteTransaction`を実装する
- 既存の並び替え条件、関連データの組み立て、保存・更新・削除の振る舞いをFirestore実装と一致させる
- Repository、QueryService、TransactionのFactoryからSQLite実装を生成できるようにする

### 6. ビルドフラグに応じてInfrastructure実装を切り替える

- Composition Rootだけがビルドフラグを参照し、オンライン用またはオフライン用のInfrastructure実装を構成する
- オンライン版では既存のFirestore、Firebase Auth、地図関連サービスの実装を使用する
- オフライン版ではSQLiteと、Firebase Authや地図などの外部サービスを利用しないためのInfrastructure実装を使用する
- Presentation、Application、Domain、UseCase、Androidウィジェットにはビルドフラグや具象データソースによる分岐を持ち込まない

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

## 不具合修正
