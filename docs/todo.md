# ToDo List

## テーブルレイアウト

- [x] pinsテーブルにlocationNameカラムを追加する

## リポジトリ

- [x] GroupRepositoryにgetGroupsWithMembersByMemberIdメソッドを追加する
- [x] GetGroupsWithMembersUsecaseをリファクタリングしてリポジトリの単一メソッドを使用する
- [x] GetManagedGroupsWithMembersUsecaseをリファクタリングしてリポジトリの単一メソッドを使用する
- [x] GroupをルートエンティティとしてGroupMemberを内部エンティティに加える
- [x] TripEntryの集約に訪問場所と詳細予定を追加しリポジトリを対応させる

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

## トップ画面

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
- [x] 並び替え：メニューの並びを「メンバー設定」と「グループ設定」の順番を入れ替える
- [x] 画面遷移制御をコントローラーに分離する
  - [x] NavigationNotifierクラスを作成する（lib/application/controllers/navigation_controller.dart）
  - [x] GroupTimelineNavigationNotifierクラスを作成する（lib/application/controllers/group_timeline_navigation_controller.dart）
  - [x] TopPageをリファクタリングしてコントローラーを使用する形に変更する

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
  - [x] AuthNotifierでGetOrCreateMemberUseCaseの戻り値を見る（Falseの場合、強制ログアウト）
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
- [x] アカウント作成画面のパスワード要件に、特殊文字で使用できる文字を明記する

## グループ管理

- [x] GroupをownerIdで抽出する処理をリポジトリに追加する
- [x] GruopMemberをmemberIdで抽出する処理をリポジトリに追加する
- [x] GetGroupsWithMembersUsecaseのexecuteメソッドを修正する
  - [x] memberを引数に取るようにする
  - [x] Group取得はgetGroupsは使用せず、getGroupsByOwnerIdを使用する（member.idを使用）
  - [x] Groupは以下の結果もマージする
    - [x] GroupMemberをgetGroupMembersByMemberIdで取得（member.idを使用）
    - [x] GroupをgetGroupsByGroupIdで取得（groupMember.groupIdを使用）
  - [x] GroupMember取得はgetGroupMembersは使用せず、getGroupMembersByGroupIdを使用する（getGroupsの結果で紐づける）
  - [x] Members取得はgetMembersは使用せず、getMemberByIdを使用する（getGroupMembersの結果で紐づける）
- [x] GroupMemberの修正
  - [x] GroupMemberはmemberを引数に取るようにする
  - [x] getGroupsWithMembersUsecase.executeにmemberを渡す
  - [x] topPageからGroupMemberにmember(ログインユーザーに紐づくmember)を渡す

## メンバー管理画面

- [x] メンバー設定メニューから開く
- [x] メンバー一覧表示
  - [x] ログインユーザーが管理しているメンバーの一覧を表示する
  - [x] ログインユーザーのmemberIdでownerIdを紐づけて取得する
  - [x] 1行目にログインユーザーに紐づくmember(TopPageの_currentMember)を表示する（削除不可とす
  る）
  - [x] ログインユーザー行の表示情報を他の行と同様に調整する
  - [x] ログインユーザー行の削除ボタンを使用不可から非表示に変更する
  - [x] 必ず1行以上存在するため、空状態メッセージの処理は不要
  - [x] 編集ボタンではなく、行タップで編集画面に遷移するように変更
- [x] メンバー新規登録
  - [x] Memberのid,accountId,ownerId以外の入力項目を作成する(モーダル画面)
  - [x] 登録時にログインユーザーのmemberIdをownerIdにセットする
- [x] メンバー情報編集
  - [x] メンバー一覧から対象メンバーの編集ボタンをクリックして開く
  - [x] メンバー新規登録と同一の情報がすべて編集可能（同一画面を使いまわす）
  - [x] 1行目のログインユーザーに紐づくメンバーを編集・更新後、反映する
    - [x] パラメータのmemberをそのまま使用せず、memberのidでDBから再取得する
    - [x] GetMemberUseCaseを使用する
- [x] メンバー削除
  - [x] メンバー一覧から対象メンバーの削除ボタンをクリック
  - [x] 確認ダイアログ(モーダル)を表示して、OKなら削除実行
- [x] newMemberの作成はcreateMemberUsecase側の責務とし、executeにeditedMemberとownerIdを渡す形に変更する
- [x] accountIdを持っているメンバーは削除不可とする（削除ボタンを表示しない）
- [x] メンバー削除時は、memberIdで紐づくテーブル（trip_participants,group_members,member_events）をすべて削除する（delete_member_usecaseで対応）
- [x] メール認証の有効化

## グループ管理画面

- [x] グループ設定メニューから開く
- [x] usecaseの作成
  - [x] GroupをownerIdで取得するusecaseを作成する（GetManagedMembersUsecaseを参考に）
  - [x] GroupMemberをgroupIdで取得するusecaseを作成する（GetGroupMembersByGroupIdUsecase）
  - [x] Groupを新規作成するusecaseを作成する（CreateMemberUsecaseを参考に）
  - [x] Groupを編集するusecaseを作成する（UpdateMemberUsecaseを参考に）
  - [x] Groupを削除するusecaseを作成する（DeleteMemberUsecaseを参考に）
- [x] グループ一覧表示(MemberManagementを参考に)
  - [x] ログインユーザーが管理しているグループの一覧を表示する
  - [x] ログインユーザーのmemberIdでownerIdを紐づけて取得する
- [x] グループ新規登録(MemberManagement,MemberEditModalを参考に)
  - [x] Groupのid,ownerId以外の入力項目を作成する(モーダル画面)
  - [x] 登録時にログインユーザーのmemberIdをownerIdにセットする
  - [x] グループに所属させるメンバーを選択できる（ログインユーザーが管理しているメンバーから選択）
  - [x] メンバー選択の対象数が多い場合、メンバー一覧のみをスクロールする
- [x] グループ情報編集(MemberManagement,MemberEditModalを参考に)
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
- [x] グループ削除(MemberManagementを参考に)
  - [x] グループ一覧から対象グループの削除ボタンをクリック
  - [x] 確認ダイアログ(モーダル)を表示して、OKなら削除実行
  - [x] グループに紐づくグループメンバーもあわせて削除する
- [x] グループ新規作成時にグループメンバーを作成した場合、group_membersのgroupIdにグループのidが入っていない不具合を修正（idを統一する必要がある）
- [x] グループに紐づくグループメンバーの削除は_deleteGroupUsecase.executeの責務とする
- [x] グループ削除時は、groupIdで紐づくテーブル（group_members,group_events,trip_entries）をすべて削除する（delete_group_usecaseで対応）
- [x] グループ削除時は、groupIdで紐づくtrip_entriesが削除されるため、tripIdで紐づくpinsとtrip_participantsも削除する（delete_group_usecaseで対応）
- [x] グループ編集モーダルのメンバー追加・変更UIをプルダウン選択に変更する
- [x] グループ編集モーダルでメンバー選択後にフォーカスを外す

## グループ年表画面

- [x] グループ一覧画面→グループ年表画面の順に遷移する
- [x] グループ年表の枠を作成
  - [x] 列：年(2025年(令和7年) というフォーマット)
  - [x] 行：旅行、イベント、グループ一覧より渡されたグループメンバーを1人1行ずつで表示する
  - [x] 現在の年を中央として、前後5年分の年を表示する
  - [x] 表示している年以上を表示したい場合、末尾と先頭に配置された「さらに表示する」をタップすると、さらに5年分の年を表示する（末尾の場合はー5年、先頭の場合は+5年）
  - [x] 初期表示時は現在の年を中央に表示する
    - [x] 年表の幅から中央位置を計算し、現在の年が中央に来るようにスクロールする
  - [x] 行の1列目はスクロールせず左端に固定する
  - [x] 列の区切り線を表示する
  - [x] スクロールテーブルの行の高さをドラッグで変更できるようにする
- [x] 左上に戻るアイコンを設置し、タップでグループ一覧画面に戻る
- [x] 旅行のセルをタップすると、旅行管理画面（モーダル）を開く
- [x] 仕様変更：旅行管理画面はモーダルではなくウィジェットにする
  - [x] 一覧→作成/編集と遷移するので今のモーダルは完全に捨てる
  - [x] 旅行管理画面に、タップしたセルの年とグループIDを渡す
- [x] 遷移先画面から戻った場合、遷移前のインスタンスを再利用する
- [x] groupTimelineの旅行行に、対象年の旅行を一覧表示する
  - [x] nameがある場合：「tripStartDateのyyyy/mm/dd \n name」形式
  - [x] nameがない場合：「tripStartDateのyyyy/mm/dd \n 旅行名未設定」形式
  - [x] 表示しきれない場合の省略処理
  - [x] 行の高さに応じた表示内容の増減
- [x] 遷移先画面から戻った場合、旅行行の内容を更新する
- [ ] グループ編集モーダルのメンバー追加・変更UIをプルダウン選択に変更する

## 旅行管理画面

- [x] 旅行一覧表示
  - [x] toppage内のウィジェットとして表示する
  - [x] タイトル、追加ボタン、リストのデザインをグループ管理画面と同様にする
  - [x] パラメータで受け取ったグループIDと年でtrip_entriesを抽出し、一覧表示する
- [x] 旅行追加ボタンを押すと、旅行作成画面（trip_edit_modal）をモーダルで表示する
- [x] 旅行作成画面
  - [x] trip_entriesの新規作成および編集で使用する
  - [x] 旅行期間From、旅行期間Toの入力フィールド
  - [x] メモの入力フィールド
  - [x] DB書き込みボタンの名称を新規作成時は「作成」、編集時は「更新」と表示する
- [x] member_managementとmember_edit_modalの構造を参考にし、
データの準備までをモーダル画面で行い、ユースケースの呼び出しは呼び出し元画面で行う
- [x] 訪問場所の入力
  - [x] メモの下に訪問場所の入力フィールドを追加する
  - [x] 訪問場所の入力フィールドの右に地図アイコンを配置する
  - [x] 地図アイコンをタップでモーダル画面上にMapDisplayを表示する
- [x] 仕様変更：「訪問場所を地図で選択」をタップでモーダル画面上にMapDisplayを表示する
- [x] 開始日と終了日がパラメータの年と異なる場合、エラーを表示する
- [x] 年またぎ旅行への対応（終了日の年チェックを削除）
- [x] パラメータの年と現在年が異なる場合、カレンダーの初期表示はパラメータの年の1月にする
- [x] 開始日が入力されている場合かつ終了日が未入力の場合、終了日タップで開くカレンダーは開始日の年月を初期値とする
- [x] 新規作成時のマップピン操作
  - [x] pinsは初期値状態（空のデータ）
  - [x] マップ上のマーカーとpinsを同期する（このタイミングはDBに書き込まない）
  - [x] 登録ボタン実行時に、旅行管理画面でtrip_entriesの登録と合わせてtripIdをキーとしてpinsを登録する
- [x] 編集時のマップピン操作
  - [x] 旅行管理画面でtrip_entriesのidでpinsのtripIdを紐づけて取得し、旅行編集画面に渡し、pinsにセットする
  - [x] マップ上のマーカーとpinsを同期する（このタイミングはDBに書き込まない）
  - [x] 更新ボタン実行時に、旅行管理画面でtrip_entriesの更新と合わせてtripIdをキーにpinsをDelete&insertする
- [x] trip_entries削除時は、tripIdで紐づくpinsとtrip_participantsを削除する（delete_trip_usecaseで対応）
- [x] onPinSavedを作成する
  - [x] 地図画面のonMarkerSavedに渡す
  - [x] pinを受け取り、_pinsから同じpinIdのデータを抽出して更新する
- [x] 「訪問場所を地図で選択」の下に訪問場所の一覧をリスト表示する
  - [x] リストのデザインは旅行管理画面の旅行一覧と同様にする（モーダル画面なので少し小さく）
  - [x] pinsのlocationName、visitStartDate、visitEndDateを表示する
  - [x] locationNameが空の場合は空白表示とする
  - [x] リストタップでボトムシートを開き、内容を編集できるようにする
  - [x] 削除ボタンを配置し、タップで該当ピンを削除する
  - [x] 訪問場所の一覧はvisitStartDateの昇順でソートして取得する（リポジトリにソート処理追加）
- [x] 「訪問場所を地図で選択」のボタン名を「地図で選択」に変更する
- [x] 旅行一覧はtripStartDateの昇順でソートする
- [x] pinエンティティを直接使用しない
- [x] pinsにgroupIdを保持する

## 地図画面

- [x] ピンタップ時にモーダルを表示するのを廃止しボトムシートに変更する
- [x] 入力域やボタンの見た目がtrip_edit_modalと異なるので、trip_edit_modal側に合わせる
- [x] GoogleMapMarkerManagerを廃止してMapDisplayをStatelessWidgetに変更する
- [x] 親ウィジェットがデータ読み書き責務を持つ
- [x] 取得した現在地情報を保持しておき、地図ウィジェットを再度生成した時の初期値とする
- [x] onMarkerSaveからonMarkerSavedをpinをパラメータとして呼び出す
- [x] pinデータが存在する場合、地図の初期位置は最初のpin位置とする
- [x] ボトムシートを開いた状態で別のピンをタップすると、ボトムシートの内容が更新されるようにする

## マップピンボトムシート

- [x] 訪問開始日と訪問終了日は時分まで入力できるようにする
- [x] 保存ボタンタップで呼び出し元にコールバックする
- [x] Pinデータを受け取り、各項目に初期セットする
- [x] 保存ボタン処理
  - [x] タップ時に訪問開始日時が訪問終了日時より後の場合にエラーメッセージを表示する
  - [x] Pinデータを作成し、呼び出し元にコールバックする
- [x] 上部にpinの位置情報からGoogle Places APIで場所名を取得して表示する
  - [x] 場所名がブランクの場合のみ、Google Places APIで場所名を取得する
  - [x] 場所名のボックス右端に更新アイコンを配置し、タップでGoogle Places APIで場所名を再取得する
  - [x] 場所名も更新処理時に保存する

## 招待機能

- [x] MemberInvitationエンティティを作成する
- [x] メンバー編集画面に(新規の時は除く)招待ボタンを配置する
- [x] 招待ボタンボタンクリックでMemberInvitationを作成
  - [x] 招待メンバーIDをinviteeId、ログインユーザーのメンバーIDをinviterIdとする
  - [x] invitationCodeはUUIDで生成
  - [x] 招待メンバーIDでinviteeIdを紐づけて、存在する場合は更新、存在しない場合は新規作成
- [x] ログイン時の処理改修
  - [x] GetOrCreateMemberUseCaseの処理を廃止
  - [x] ログイン時に、ユーザーIDでメンバーのAccountIdを紐づけて、存在チェック
  - [x] 存在しない場合にダイアログを表示し、新規作成or招待コード入力を選択
    - [x] 新規作成の場合は、displayName: user.loginId, accountId: user.id, email: user.loginId,でメンバー作成
    - [x] 招待コード入力の場合は、入力されたコードでMemberInvitationを紐づけ、accountIdにuser.idをセットして更新する
    - [x] 入力された招待コードで紐づかない場合はエラー表示（新規作成はしない。）
- [x] 招待受諾時、inviteeIdでmembers.idを取得し、accountIdがnullでない場合は無効と判定して更新しない

## デザイン

- [x] ベースカラーを青系統に変更する
- [ ] メニュー名がシステム的なので、名称を変更する
  
## リファクタリング

- [x] GroupDtoを作成する
  - [x] GroupMemberDtoとGroupEventDtoも作成し、GroupDtoにリストとして保持する
  - [x] マッパーも用意する

## 全体

- [x] 画面の一部にポップアップして表示する画面のファイル名の末尾は"dialog"ではなく"modal"で統一する
- [x] エンティティの設計をuser.dartに合わせる
- [x] DatePickerの操作性改善（日付タップで直接確定）
  - [x] DatePickerダイアログ上部の年月日表記に曜日も表示する
  - [x] DatePickerダイアログ上部の年月日表記タップで直接入力で年月日を変更できるようにする
- [x] _showDeleteConfirmDialog（削除ダイアログ）の共通ウィジェット化
