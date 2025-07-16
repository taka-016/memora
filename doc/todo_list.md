# ToDo List

## マップの表示
- [x] 起動時に現在地に移動

## マップピンのポップアップメニュー表示
- [x] ピンをタップでポップアップメニュー表示
  - [x] 「削除」メニューの追加

## マップピンの取得・表示・削除
- [x] ピン位置の保存
    - [x] ピン位置をFirebaseに保存する処理
    - [x] 保存成功・失敗時のUI反映
    - [x] UUID、ピン位置の保存
- [x] マップ起動時に保存済みのピンをマップに表示
    - [x] Firebaseからピン位置リストを取得
    - [x] ピンリストをマップ上に配置
- [x] 削除ボタンタップ時にピン位置を削除
    - [x] Firebaseから該当ピンを削除する処理
    - [x] マップ上から該当ピンを削除
    - [x] markerIdで紐づけて削除する

## マップの検索機能追加
- [x] 汎用検索バーWidgetを作成する
- [x] 検索バーをマップ上に配置
- [x] 検索バーに入力されたキーワードで位置検索
- [x] 検索結果の位置に地図を移動

## 詳細入力画面の追加
- [x] ピンをタップしたときに詳細入力画面をモーダル表示
- [x] 詳細入力画面のUIを作成
  - [x] 旅行期間From、旅行期間Toの入力フィールド
  - [x] メモの入力フィールド（旅の記録というラベルで）

## 画面の改修
- [x] Googleマップ画面は別画面でも使用するため、ウィジェット化する
  - [x] google_map_screenはウィジェットを表示する形にする
- [x] トップページを作成する。
  - [x] トップにはグループの情報が表示される
  - [x] グループが複数件ある場合は、グループ一覧が表示される
  - [x] グループが1件しかない場合は、グループ一覧ではなくグループのメンバー一覧が表示される
  - [x] グループが存在しない場合は、グループ作成ボタンが表示される
  - [x] グループを選択すると、そのグループ内のメンバー一覧が表示される
  - [x] グループにメンバーが存在しない場合は、メンバー追加ボタンが表示される
- [x] アプリ起動時にトップページを表示する
- [x] HomePageは廃止する
- [x] トップページの構成を変更
  - [x] トップページの左上にハンバーガーメニューを追加する
  - [x] 常にトップページが表示され、メニューで選択された機能のウィジェットが表示されるようにする
  - [x] メニュー項目はトップページ、グループ年表、マップ表示、グループ設定、メンバー設定、設定とする（トップページが初期表示のグループ情報のこと）
- [x] GroupMemberウィジェットの改修
  - [x] 変更：グループが複数件ある場合は、グループ一覧が表示される→グループが1件でもグループ一覧を表示する
  - [x] 廃止：グループが1件しかない場合は、グループ一覧ではなくグループのメンバー一覧が表示される
  - [x] 廃止：グループにメンバーが存在しない場合は、メンバー追加ボタンが表示される
  - [x] 廃止：グループを選択すると、そのグループ内のメンバー一覧が表示される
  - [x] 変更：グループが存在しない場合は、グループ作成ボタンが表示される→「グループがありません」のラベル表示のみ
  - [x] 変更：トップページというメニューは廃止し、グループ年表のメニューからGroupMemberに遷移する

## アカウント管理
- [x] アカウント管理はGoogle Cloud Identity Platformを使用する
  - [x] 認証関連のエンティティ作成（User, AuthState等）
  - [x] 認証サービス抽象化インターフェース作成
  - [x] Firebase Auth実装クラス作成
  - [x] 認証ユースケース実装（ログイン、ログアウト、サインアップ等）
  - [x] 認証状態管理マネージャー作成
  - [x] ログイン・サインアップ画面UI実装
  - [x] 認証ガード機能実装（未認証時のリダイレクト処理）
- [x] ログイン成功時に、アカウントのUIDでmembersのaccountIdを紐づけて取得する
  - [x] UIDでmembersが紐づかなかった場合、membersを新規作成しaccountIdにUIDを保持させる
  - [x] GetOrCreateMemberUseCaseは戻り値をbooleanにする
  - [x] AuthManagerでGetOrCreateMemberUseCaseの戻り値を見る（Falseの場合、強制ログアウト）
- [x] ログアウトボタンはメニューの最下部に配置する
- [x] ログインユーザーのニックネームをメニューの上部に表示する
- [x] ログインユーザーのニックネームが未設定の場合は、kanjiLastName+半角スペース+kanjiFirstNameを表示する
- [x] ログインユーザーのkanjiLastNameとkanjiFirstNameが両方未設定の場合は、"名前未設定"と表示する
- [x] 仕様変更：ニックネーム→表示名という必須フィールドに変更したため、常にログインユーザーの表示名を表示する
- [x] 仕様変更：メニューの上部に表示する表示名は、ログインIDに変更する
- [x] アカウント設定画面を作成する
  - [x] メニューの「アカウント設定」から遷移できるようにする
  - [x] メールアドレスの変更機能
  - [x] パスワードの変更機能
  - [x] アカウント削除機能
- [x] パスワードポリシーを大文字、小文字、特殊文字、数字が必要かつ最低8文字以上とする
- [x] firestoreのローカルキャッシュを無効化する
- [x] トークンの有効期限が切れている場合はログイン画面に戻す

## グループ管理
- [x] GroupをadministratorIdで抽出する処理をリポジトリに追加する
- [x] GruopMemberをmemberIdで抽出する処理をリポジトリに追加する
- [x] GetGroupsWithMembersUsecaseのexecuteメソッドを修正する
  - [x] memberを引数に取るようにする
  - [x] Group取得はgetGroupsは使用せず、getGroupsByAdministratorIdを使用する（member.idを使用）
  - [x] Groupは以下の結果もマージする
    - [x] GroupMemberをgetGroupMembersByMemberIdで取得（member.idを使用）
    - [x] GroupをgetGroupsByGroupIdで取得（groupMember.groupIdを使用）
  - [x] GroupMember取得はgetGroupMembersは使用せず、getGroupMembersByGroupIdを使用する（getGroupsの結果で紐づける）
  - [x] Members取得はgetMembersは使用せず、getMemberByIdを使用する（getGroupMembersの結果で紐づける）
- [x] GroupMemberの修正
  - [x] GroupMemberはmemberを引数に取るようにする
  - [x] getGroupsWithMembersUsecase.executeにmemberを渡す
  - [x] topPageからGroupMemberにmember(ログインユーザーに紐づくmember)を渡す

## メンバー設定画面
- [x] メンバー設定メニューから開く
- [x] メンバー一覧表示
  - [x] ログインユーザーが管理しているメンバーの一覧を表示する
  - [x] ログインユーザーのmemberIdでadministratorIdを紐づけて取得する
  - [x] 1行目にログインユーザーに紐づくmember(TopPageの_currentMember)を表示する（削除不可とす
  る）
  - [x] ログインユーザー行の表示情報を他の行と同様に調整する
  - [x] ログインユーザー行の削除ボタンを使用不可から非表示に変更する
  - [x] 必ず1行以上存在するため、空状態メッセージの処理は不要
  - [x] 編集ボタンではなく、行タップで編集画面に遷移するように変更
- [x] メンバー新規登録
  - [x] Memberのid,accountId,administratorId以外の入力項目を作成する(モーダル画面)
  - [x] 登録時にログインユーザーのmemberIdをadministratorIdにセットする
- [x] メンバー情報編集
  - [x] メンバー一覧から対象メンバーの編集ボタンをクリックして開く
  - [x] メンバー新規登録と同一の情報がすべて編集可能（同一画面を使いまわす）
  - [x] 1行目のログインユーザーに紐づくメンバーを編集・更新後、反映する
    - [x] パラメータのmemberをそのまま使用せず、memberのidでDBから再取得する
    - [x] GetMemberUseCaseを使用する
- [x] メンバー削除
  - [x] メンバー一覧から対象メンバーの削除ボタンをクリック
  - [x] 確認ダイアログ(モーダル)を表示して、OKなら削除実行

## グループ設定画面
- [x] グループ設定メニューから開く
- [x] usecaseの作成
  - [x] GroupをadministratorIdで取得するusecaseを作成する（GetManagedMembersUsecaseを参考に）
  - [x] GroupMemberをgroupIdで取得するusecaseを作成する（GetGroupMembersByGroupIdUsecase）
  - [x] Groupを新規作成するusecaseを作成する（CreateMemberUsecaseを参考に）
  - [x] Groupを編集するusecaseを作成する（UpdateMemberUsecaseを参考に）
  - [x] Groupを削除するusecaseを作成する（DeleteMemberUsecaseを参考に）
- [x] グループ一覧表示(MemberSettingsを参考に)
  - [x] ログインユーザーが管理しているグループの一覧を表示する
  - [x] ログインユーザーのmemberIdでadministratorIdを紐づけて取得する
- [x] グループ新規登録(MemberSettings,MemberEditModalを参考に)
  - [x] Groupのid,administratorId以外の入力項目を作成する(モーダル画面)
  - [x] 登録時にログインユーザーのmemberIdをadministratorIdにセットする
  - [x] グループに所属させるメンバーを選択できる（ログインユーザーが管理しているメンバーから選択）
  - [x] メンバー選択の対象数が多い場合、メンバー一覧のみをスクロールする
- [x] グループ情報編集(MemberSettings,MemberEditModalを参考に)
  - [x] グループ一覧から対象グループの行をクリックして編集する
  - [x] グループ新規登録と同一の情報がすべて編集可能（同一画面を使いまわす）
  - [x] グループに所属させるメンバーの追加削除ができる（ログインユーザーが管理しているメンバーから選択）
- [x] GetManagedGroupsUsecaseをGetManagedGroupsWithMembersUsecaseに改修
  - [x] GetManagedGroupsUsecaseにメンバー情報も取得する機能を追加
  - [x] ファイル名とクラス名をget_managed_groups_with_members_usecaseに変更
  - [x] グループ設定画面でGetManagedGroupsWithMembersUsecaseを使用
- [x] _showGroupEditModalの既存グループメンバー取得処理を削除
  - [x] GetManagedGroupsWithMembersUsecaseで既にメンバー情報を取得しているため、重複する処理を削除
  - [x] 編集モーダルには内部で保持しているメンバー情報を渡すように変更
- [x] グループメンバー更新時の効率化
  - [x] DeleteGroupMembersByGroupIdUsecaseを作成
  - [x] 既存のGroupMember削除処理で_getGroupMembersByGroupIdUsecaseの重複呼び出しを削除
  - [x] 新しいユースケースを使用してグループのすべてのメンバーを一括削除
- [x] グループ削除(MemberSettingsを参考に)
  - [x] グループ一覧から対象グループの削除ボタンをクリック
  - [x] 確認ダイアログ(モーダル)を表示して、OKなら削除実行
  - [x] グループに紐づくグループメンバーもあわせて削除する
- [x] グループ新規作成時にグループメンバーを作成した場合、group_membersのgroupIdにグループのidが入っていない不具合を修正（idを統一する必要がある）

## グループ一覧
- [ ] グループ年表メニューからgroup_member.dartを開く
- [ ] get_groups_with_members_usecaseで取得したグループ一覧をリスト表示し、メンバー情報は裏で保持する
- [ ] グループをタップするとグループ年表ウィジェットに切り替わる

## グループ年表ウィジェット
- [ ] 列が年(西暦＋和暦)、行が旅行(trip_entries)、グループイベント(group_events)、メンバー(group_members)を1人1行ずつで表示する

## デザイン
- [ ] ベースカラーを緑系統に変更する
- [ ] メニュー名がシステム的なので、名称を変更する

## 全体
- [x] 画面の一部にポップアップして表示する画面のファイル名の末尾は"dialog"ではなく"modal"で統一する
- [x] エンティティの設計をuser.dartに合わせる