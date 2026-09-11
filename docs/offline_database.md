# オフラインDB設計

## 保存先とライフサイクル

Driftの`NativeDatabase.createInBackground`を使い、Androidのアプリ内部ストレージにある`getApplicationSupportDirectory()`配下の`memora.sqlite`へ保存する。アプリ独自のDB暗号化は適用しない。

Composition Rootの`offlineDatabaseProvider`が接続を所有する。Factoryと本人復元は同じProviderのDBを共有し、初回アクセス時に`LazyDatabase`がファイル・スキーマを初期化する。Providerの破棄時に接続を閉じる。独立してDBを使う処理では`initialize()`と`close()`を対にする。通常のバックグラウンドDB処理は別isolate上で実行され、UI isolateをブロックしない。

AndroidウィジェットのバックグラウンドComposition Rootへの接続と、手動バックアップ・復元の画面およびファイル処理は、それぞれtodo 7・8で対応する。

## 業務データと制約

物理定義の正本は[`offline_schema.drift`](../lib/infrastructure/database/offline_schema.drift)。全列の型、NOT NULL、外部キー、CHECK、一意制約とindexをここに定義し、Driftで生成する。Entity・DTOのcamelCaseはMapperでsnake_caseへ変換する。

| テーブル | 主キー・一意性 | 関連と削除時の扱い | 主な検索・並び替え |
| --- | --- | --- | --- |
| members | id、account_idは非null値で一意 | owner_idはmembersを参照。所有するメンバーやグループがある本人の削除はRESTRICT | owner_id、表示名による並び替え |
| groups | id | owner_idはmembersを参照、RESTRICT | owner_id、グループ名による並び替え |
| group_members | (group_id, member_id) | グループまたはメンバー削除でCASCADE | group_idまたはmember_idとorder_indexの複合index |
| member_events | id、(member_id, year)は一意 | メンバー削除でCASCADE | member_idとyearの一意index |
| group_events | id。同年の複数件を許可 | グループ削除でCASCADE | group_idとyearの複合index |
| trip_entries | id | グループ削除でCASCADE | group_idとyearの複合index |
| tasks | id、(id, trip_id)は一意 | 旅行削除でCASCADE、担当メンバー削除でSET NULL | trip_idとorder_index、担当メンバー、親タスクのindex |
| itinerary_items | id | 旅行削除でCASCADE | trip_idとstart_date_timeの複合index |
| dvc_point_contracts | id | グループ削除でCASCADE | group_idとcontract_start_year_monthの複合index |
| dvc_limited_points | id | グループ削除でCASCADE | group_idとstart_year_monthの複合index |
| dvc_point_usages | id | グループ削除でCASCADE | group_idとusage_year_monthの複合index |

タスクの親参照は`(parent_task_id, trip_id)`から`(id, trip_id)`への複合外部キーで、他の旅行のタスクを親にできない。`DEFERRABLE INITIALLY DEFERRED`により、子が親より先に入力されてもトランザクション終了時に整合していれば保存できる。親だけを削除して子を残す操作は拒否する。旅行の子データは集約単位で置換・削除する。

グループと所属の保存・置換は`GroupRepository`、旅行・タスク・旅程の保存・置換・削除は`TripEntryRepository`のトランザクションにまとめる。`SqliteWriteTransaction`は既存の`WriteTransactionScope`と同様に旅行Repositoryを提供し、複数旅行の変更も全件コミットまたはロールバックする。関連データを組み立てるQueryServiceも同一の読み取りトランザクションを使う。

メンバー、グループ、旅行、DVCの新規保存時はUUIDを発行する。旅程・タスクは集約で渡されたIDを維持する。グループイベントはIDが空なら新規作成、既存IDなら更新する。メンバーイベントは本人IDと年からIDを決め、同年の内容を置換し、空メモなら削除する。

## 値の保存形式

- 日時はUnix epochからのマイクロ秒をSQLiteのINTEGERへ保存し、Firestoreの日時変換と同じく端末ローカルの`DateTime`として復元する。日付・年月も同じ形式を使い、Mapperでは丸めない。
- 真偽値はINTEGERの0/1。CHECK制約で他の値を拒否する。
- 任意項目はSQL NULL。更新時もnullを明示して、以前の値を解除できる。
- アプリの`OrderBy`はスキーマに存在する列へ変換・検証する。指定した順序で複数列の昇順・降順を適用し、SQLiteのNULL順序（昇順では先頭）を使う。
- DBアクセスの失敗は呼び出し元へ伝え、データなしと区別して既存の再試行処理へつなぐ。

## 保存しないデータと復元入力の検証

`passportNumber`、`passportExpiration`、`locations`、`member_invitations`、旅程の`locationId`はSQLiteに保存しない。旅行DTOの場所一覧は空配列、旅程DTOの`locationId`・`location`はnullになる。

場所一覧が空でない旅行、または`locationId`が非nullの旅程は、`SqliteTripEntryMapper.validate`・`SqliteItineraryItemMapper.validate`が共通の`FeatureUnavailableException(AppFeature.maps)`で拒否する。Repositoryは書き込み開始前に検証し、Mapperの`toRow`でも同じ検証を行う。場所を除去して保存する補正は行わない。

todo 8の論理バックアップ復元でも、入力をEntityへ変換してこの検証を通してから書き込む。ファイル全体の形式・バージョン・未知フィールド・業務上の不変条件の検証も必要であり、DB用の`fromRow`をバックアップファイルのパーサーとして使用しない。場所付き入力は復元全体を拒否し、現在のデータを維持する。生SQLによる未知の場所列への書き込みもスキーマで拒否される。

## 端末内の本人情報

既存の`offline_current_member.json`を`LocalCurrentMemberResolver`で読み、本人メンバーIDと利用者ID（accountId）を引き継ぐ。SQLiteに本人が未登録の場合のみそのIDで登録する。以後は`SqliteCurrentMemberResolver`がSQLiteの本人情報を返すため、名前や生年月日等の編集結果がDB再オープン後にも反映される。JSONが破損している場合は既存どおりエラーを返し、新しい利用者で上書きしない。

## バージョンとマイグレーション

初期バージョンは1。新規DBはDriftの`Migrator.createAll()`で作成し、毎回の接続で`PRAGMA foreign_keys = ON`を設定する。現在は旧SQLiteバージョンが存在しないため、異なるバージョンはエラーとし、削除・再作成・暗黙のダウングレードはしない。

リリース後のスキーマ変更では、`schemaVersion`を上げ、旧バージョンからの移行を`onUpgrade`へ明示的に追加する。既存データを保存した旧DBからの移行、失敗時のロールバック、移行後の`foreign_key_check`と全体チェックを必須にする。テーブル再作成が必要な移行でも、既存ファイルの削除で代替しない。

## 検証と参照資料

`test/unit/infrastructure/database/`で、集約の保存・取得・更新・削除、関連データの組み立て、並び替え、日時とnullの復元、制約違反、ロールバック、本人IDの引き継ぎ、DB再オープン、未対応バージョンの拒否を検証する。Factoryの選択は`test/unit/composition_root/app_mode_services_test.dart`で検証する。

導入前にContext7で[Driftのセットアップ](https://drift.simonbinder.eu/setup/)、[ネイティブ接続](https://drift.simonbinder.eu/platforms/vm/)、[マイグレーションAPI](https://drift.simonbinder.eu/migrations/api/)を確認した。
