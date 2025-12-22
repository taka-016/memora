# ToDo List

## テーブルレイアウト

- [x] pinsテーブルにlocationNameカラムを追加する
- [x] group_membersにisAdministratorを追加する

## リポジトリ

- [x] GroupWithMembersDtoのマッパーを作成する
- [x] GroupWithMembersMapperにtoEntityとtoEntityListを追加する
- [x] GroupWithMembersDtoにownerIdを追加する
- [x] GroupRepositoryにgetGroupsWithMembersByMemberIdメソッドを追加する
- [x] GetGroupsWithMembersUsecaseをリファクタリングしてリポジトリの単一メソッドを使用する
- [x] GetManagedGroupsWithMembersUsecaseをリファクタリングしてリポジトリの単一メソッドを使用する
- [x] GroupをルートエンティティとしてGroupMemberを内部エンティティに加える
- [x] TripEntryの集約に訪問場所と詳細予定を追加しリポジトリを対応させる
  - [x] getTripEntries→getTripEntriesByGroupIdに変更
  - [x] getで子エンティティも取得する
  - [x] save,update,deleteも子エンティティに対応する
- [x] GetPinsByTripIdUseCaseの使用を廃止し、GetTripEntriesUsecaseで取得したpinsデータを使用する
- [x] FirestorePinQueryServiceを作成し、自分が所属するグループに紐づくピンを取得する
- [x] TripEntryRepositoryのgetTripEntryByIdにpinsとpinDetails用のorderByを設定できるようにする
- [x] MemberRepositoryのgetMembersとgetMembersByOwnerIdにorderByを追加する
  - [x] GetManagedMembersUsecaseでdisplayNameの昇順で取得する処理を追加する
- [x] GroupRepositoryのgetGroups、getGroupsByOwnerId、getGroupByIdにorderByを追加する
  - [x] getGroups、getGroupsByOwnerIdはgroupsのソートのためのorderBy、getGroupByIdはmembersのソートのためのorderBy
- [x] FirestoreGroupQueryServiceのgetGroupsWithMembersByMemberIdにorderByを追加する
  - [x] groupsのソートのためのorderBy、membersのソートのためのorderByを追加する
  - [x] GetGroupsWithMembersUsecaseでgroupsのnameの昇順とmembersのdisplayNameの昇順で取得する処理を追加する
- [x] FirestoreGroupQueryServiceのgetManagedGroupsWithMembersByOwnerIdにorderByを追加する
  - [x] groupsのソートのためのorderBy、membersのソートのためのorderByを追加する
  - [x] GetManagedGroupsWithMembersUsecaseでgroupsのnameの昇順とmembersのdisplayNameの昇順で取得する処理を追加する
- [x] getGroups、getGroupsByOwnerIdは使用していないため廃止する
- [x] getGroupByIdのorderByはgroup_memberではソートキーとなる要素がないため廃止する
- [x] FirestoreGroupQueryServiceにgetGroupWithMembersByIdを追加する
  - [x] グループIDでgroupsを取得し、その子エンティティであるgroup_membersを紐づけmember_idでmembersも紐づけて取得する
  - [x] 取得結果はGroupWithMembersDtoに格納する
- [x] GroupDtoをEquatable化して、copyWithも追加する
- [x] TripEntryRepositoryのgetTripEntryById,getTripEntriesByGroupId,getTripEntriesByGroupIdAndYearをTripEntryQueryServiceに実装する（段階的に移行するので、この時点ではTripEntryRepositoryにも残しておく）
- [x] MemberRepositoryのgetMembers,getMemberById,getMemberByAccountId,getMembersByOwnerIdをMemberQueryServiceに実装する（段階的に移行するので、この時点ではMemberRepositoryにも残しておく）
- [x] MemberInvitationRepositoryのgetByInviteeId,getByInvitationCodeをMemberInvitationQueryServiceに実装する（段階的に移行するので、この時点ではMemberInvitationRepositoryにも残しておく）
- [x] TripEntryDtoを作成する
- [x] PinDetailDtoを作成する
- [x] MemberInvitationDtoを作成する
- [x] GroupEventDtoを作成する
- [x] MemberEventDtoを作成する
- [x] TripEntryMapperを作成する
- [x] PinDetailMapperを作成する
- [x] MemberInvitationMapperを作成する
- [x] GroupEventMapperを作成する
- [x] MemberEventMapperを作成する
- [x] FirestoreMemberQueryServiceのレスポンスはDtoを返すように変更する
  - [x] getMembersの戻り値をMemberDtoに変更する
  - [x] getMemberByIdの戻り値をMemberDtoに変更する
  - [x] getMemberByAccountIdの戻り値をMemberDtoに変更する
  - [x] getMembersByOwnerIdの戻り値をMemberDtoに変更する
- [x] TripEntryQueryServiceのレスポンスはDtoを返すように変更する
  - [x] getTripEntryByIdの戻り値をTripEntryDtoに変更する
  - [x] getTripEntriesByGroupIdAndYearの戻り値をTripEntryDtoに変更する
- [x] MemberInvitationQueryServiceのレスポンスはDtoを返すように変更する
  - [x] getByInviteeIdの戻り値をMemberInvitationDtoに変更する
  - [x] getByInvitationCodeの戻り値をMemberInvitationDtoに変更する
- [x] ER図のroutesテーブル定義を元にRouteエンティティを作成する
  - [x] lib/domain/entities/trip/route.dartの作成
  - [x] lib/application/dtos/trip/route_dto.dartの作成
  - [x] lib/domain/repositories/trip/route_repository.dartの作成
  - [x] lib/application/queries/trip/route_query_service.dartの作成
  - [x] lib/infrastructure/repositories/trip/firestore_route_repository.dartの作成
  - [x] lib/infrastructure/queries/trip/firestore_route_query_service.dartの作成
  - [x] lib/infrastructure/mappers/trip/route_mapper.dartの作成
  - [x] lib/application/mappers/trip/route_mapper.dartの作成
- [x] RouteエンティティはTripEntryエンティティの集約に加える
  - [x] TripEntryRepository、TripEntryQueryService、FirestoreTripEntryRepository、FirestoreTripEntryQueryServiceを対応させる
  - [x] TripEntryMapper、TripEntryDtoを対応させる
  - [x] Routeエンティティクラスにidは含めない（関連処理もあわせて修正する）
  - [x] RouteRepositoryを廃止し、関連実装・テスト・DIから除去する

## マップの表示

- [x] ~~起動時に現在地に移動~~→仕様変更により廃止
- [x] 地図表示画面はMapViewを直接表示するのではなく、mapDisplayウィジェットを表示してその上にMapViewを生成する形にする
- [x] PinQueryServiceのgetPinsByMemberIdを使用してログインユーザー(ユーザーIDに紐づくmember)が所属するグループに紐づくpinsを取得する
  - [x] 取得したpinsをマップにmarkerで表示する
  - [x] markerタップでpin内容を表示するが、変更/削除は不可とする

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
- [x] トップページのヘッダ色をハンバーガーメニューのヘッダ色と合わせる
- [x] _currentMember取得でエラーになった場合、showSnackBarでエラーを表示し、そのままログアウトする

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
- [x] AccountDeleteModalの削除処理をAccountSettingsで実行する

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
- [x] グループオーナーは必ずグループメンバーに含める
  - [x] グループ新規画面のメンバー一覧の先頭にログインユーザーを固定表示し、新規/編集モードともに削除不可かつ管理者固定で変更不可（＝アクションメニューのボタンを表示しない）

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
- [x] 生年月日は未来日付も入力可能にする

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
- [x] グループ編集モーダルのメンバー一覧表示を操作メニュー付きで改善する
- [x] メンバー一覧で管理者を設定可能にする
- [x] GroupEditModalのgroupをGroupDtoに変更する
  - [x] GroupManagementの_showEditGroupDialogは_getGroupByIdUsecaseを使用せず、GroupEditModalのgroupにgroupWithMembersをそのまま渡す
  - [x] GroupMemberではなくGroupMemberDtoを使用する
  - [x] onSaveに渡す際にGroupMapperのtoEntityでGroupエンティティを渡す

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
- [x] グループメンバー行の各カラムの1行目に、年齢を表示する
  - [x] 年齢はその年の12月31日時点での年齢とする
  - [x] 生年月日が登録されていない場合は空白とする

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
- [x] 「経路情報」ボタンの追加
  - [x] 旅行編集画面に「経路情報」ボタンを追加する
  - [x] ボタンをタップで経路情報ダイアログを表示する（新規ウィジェットとしてlib/presentation/shared/dialogs以下に作る）
  - [x] pinのリストが並んでおり、順番をドラッグで入れ替えられる
  - [x] 各pin間はスペースが開いて下矢印でつながっており、矢印に右に移動手段のプルダウンがある
    - [x] プルダウンは、自動車(DRIVE)、徒歩(WALK)、~~公共交通機関(TRANSIT)~~が選択可能で、初期値は自動車(DRIVE)
    - [x] 表示領域が限られているので、プルダウン以外の余計な情報を表示しない
    - [x] プルダウンにその他(OTHER)を追加し、選択時にプルダウンの右にテキスト入力欄を表示して自由入力できるようにする
    - [x] プルダウンにその他(OTHER)を選択した箇所はAPIを呼び出さず、Polylineは前Pinの位置から後Pinの位置までを直線で結ぶ
  - [x] Pinが多い場合はスクロールできるようにする
  - [x] PinはlocationNameのみ表示し、visitStartDate、visitEndDateは表示しない
  - [x] ダイアログ上部に「経路検索」ボタンを配置し、タップでGoogleのRoutes APIを使用して経路情報を取得する
    - [x] 出発時間の指定は不要
    - [x] 中間地点は使用せず、各pin間の経路に設定された移動手段で1回ずつAPIを呼び出して取得する
    - [x] つまり、pinが3つある場合は、pin1→pin2、pin2→pin3の2回APIを呼び出す
- [x] ダイアログ画面の下半分にGoogleMapを表示し、取得した経路情報をMap上に表示する
  - [x] 各Pinをタップで、GoogleMap上の対象となる経路をハイライト表示する
  - [x] GoogleMapはmap_viewsは使用せず、このダイアログ用にMapを生成する
  - [x] +/-アイコンでGoogleMapは表示/非表示を切り替えられるようにする
  - [x] 経路ごとに異なる色でPolylineを表示する（最大10色用意し、11個目の経路以降は1色目から再利用する）
  - [x] Pinの下に経路詳細を表示する
    - [x] DropdownButtonの右に表示する
    - [x] Pin間の距離(km)と所要時間(分)、経路案内を表示する
    - [x] 距離が設定されていない場合は、所要時間(分)のみ表示する
    - [x] 経路詳細は折りたたみ表示とし、タップで展開/折りたたみできるようにする
    - [x] 経路詳細のボリュームに合わせてPin間の高さが変わるようにする
    - [x] 仕様変更：アコーディオンボタンには「ルートメモ」と表示し、距離、所要時間、経路案内は展開した中のメモとして表示する
    - [x] 「ルートメモ」は検索有無にかかわらず表示する
- [x] 旅行編集画面の経路検索を「地図で選択」と同じダイアログ内の表示切り替えに変更し、ウィジェット名からdialogを外す
- [x] 「地図で選択」ボタンを「訪問場所を選択」に名称変更する
- [x] 旅行編集画面の「訪問場所を選択」の表示処理をselect_visit_location_view.dartに切り出す
  - [x] _buildSelectVisitLocationExpandedLayoutが_buildRouteInfoExpandedLayoutと同様にreturn SelectVisitLocationViewになるようにする
- [x] 自由入力の入力欄を廃止し、「その他」選択時は右に経路入力用のアイコンを配置する（Editアイコン）
- [x] 経路入力用のアイコンをタップすると、経路入力用のボトムシートが表示されるようにする
  - [x] ボトムシートはlib/presentation/shared/sheets以下に新規作成し、名称はother_route_info_bottom_sheet.dartとする
- [x] ボトムシート内の項目は以下のとおり
  - [x] 所要時間(分)の入力欄（数字のみ）
  - [x] 経路案内の入力欄（複数行テキスト）
  - [x] 保存ボタンは用意せず、入力欄のフォーカスが外れたタイミングで内部保持する
  - [x] 入力内容は、「その他」で経路検索した時の経路情報に表示する
  - [x] ボトムシートを閉じると、即時にルートメモに反映される（検索の有無にかかわらず表示）
- [x] 「訪問場所を選択」と「経路情報」ボタンの配置を横並びにする
- [x] 「訪問場所を選択」ボタンの名称を「編集」に変更する
- [x] 「編集」と「経路情報」ボタンにアイコンを追加する
- [x] RouteMemoEditBottomSheetで入力した内容はRouteMemoEditFormValueではなく、
RouteSegmentDetailに保持する（_otherRouteInfoInputsを廃止する）
  - [x] _searchRoutesでotherの場合はRouteMemoEditBottomSheetでRouteSegmentDetailを作成しているため、
  polylineの内容のみマージする
- [x] 経路マップを閉じている場合に「経路検索」を実行するとエラーが発生する不具合を修正
- [x] trip_entryのtripStartDate(旅行開始日)とtripEndDate(旅行終了日)は任意入力とする
  - [x] trip_entryにtripYear("NOT NULL")を追加し、年での紐づけはすべてtripYearで行う
  - [x] エンティティ、リポジトリ、ユースケース、マッパー、DTO、画面の修正
  - [x] エンティティでのpinの訪問開始日、訪問終了日のチェックはtripStartDate、tripEndDateが存在する場合は日付を含めてチェックし、存在しない場合は年のみでチェックする
- [x] 旅行編集画面の旅行開始日、旅行終了日をクリア可能にする
  - [x] CopyWithでnull代入を可能にする必要あり

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
  - [x] この仕様を廃止する（accountIdがnullでない場合でも更新する）
  - [ ] 招待コードで紐づけたmemberを更新した後、使用済み招待コードのレコードは削除する
- [ ] 作成から24時間経過した招待コードは無効とする

## デザイン

- [x] ベースカラーを青系統に変更する
- [ ] メニュー名がシステム的なので、名称を変更する
  
## リファクタリング

- [x] GroupDtoを作成する
  - [x] GroupMemberDtoとGroupEventDtoも作成し、GroupDtoにリストとして保持する
  - [x] マッパーも用意する
- [x] Repository Factoryパターンを導入してDB切り替えを可能にする
  - [x] DatabaseTypeのenumとRiverpod Providerを作成
  - [x] RepositoryFactoryを実装
- [x] QueryService Factoryパターンを導入してDB切り替えを可能にする
  - [x] QueryServiceFactoryを実装
- [x] TopPageにUseCaseを渡さない
- [x] GroupListにUseCaseを渡さない
- [x] AuthService Factoryパターンを導入してサービスを切り替えを可能にする
  - [x] AuthTypeのenumとRiverpod Providerを作成
  - [x] AuthServiceFactoryを実装
- [x] UseCaseをProviderに依存する形に変更する
  - [x] GroupManagementで実装
- [x] UseCase Providerを利用するようにリポジトリDIをリファクタリングする
  - [x] 全機能に展開する
- [x] 以下、StateNotifierになっている箇所をNotifierに変更する
  - [x] AuthNotifier
  - [x] LocationNotifier
  - [x] NavigationNotifier
  - [x] GroupTimelineNavigationNotifier
- [x] GroupTimelineのConsumerStatefulWidgetを廃止し、HookConsumerWidgetにする
- [x] route_info_view.dartをroute_info_view.dart,route_list.dart,route_map.dartに分割する
- [x] RouteList/RouteMapウィジェット側に関連ロジックも集約する
- [x] 経路情報の取得処理をusecaseに切り出す（RouteInfoViewのsearchRoutesロジック）
- [x] RouteInfoViewでのGoogleRoutesApiRouteInfoService直接生成を廃止し、usecase経由で取得する（Env参照含む）
- [x] 以下の画面のStatefulWidget(またはConsumerStatefulWidget)をHookWidget(またはHookConsumerWidget)に変更する
  - [x] TopPage
  - [x] AccountDeleteModal
  - [x] EmailChangeModal
  - [x] PasswordChangeModal
  - [x] ReauthenticateModal
  - [x] LoginPage
  - [x] SignUpPage
  - [x] GroupEditModal
  - [x] GroupManagement
  - [x] MapScreen
  - [x] MemberEditModal
  - [x] MemberManagement
  - [x] TripEditModal
  - [x] TripManagement
  - [x] GroupList
  - [x] CustomDatePickerDialog
  - [x] InvitationCodeModal
  - [x] CustomSearchBar
  - [x] GoogleMapView
  - [x] PinDetailBottomSheet
  - [x] RouteMemoEditBottomSheet
  - [x] RouteInfoView
- [x] TopPageで取得しているcurrentMemberをRiverpodでグローバル管理する
  - [x] currentMemberの取得責務をNotifier/Providerに移す
  - [x] 各画面へのmember引数受け渡しを廃止する

## 不具合修正

- [x] グループ管理画面とメンバー管理画面で、編集後に一覧画面に戻った際、一覧が最新状態に更新されず、再度編集を開くと古いデータのままになっている不具合を修正する
（旅行管理画面と動きを合わせる。）
  - [x] グループ管理画面
  - [x] メンバー管理画面
  - [x] グループ編集画面で、メモ欄を空欄にして更新して再度開くと元に戻っている（空欄が反映されない）不具合を修正する

## 全体

- [x] 画面の一部にポップアップして表示する画面のファイル名の末尾は"dialog"ではなく"modal"で統一する
- [x] エンティティの設計をuser.dartに合わせる
- [x] DatePickerの操作性改善（日付タップで直接確定）
  - [x] DatePickerダイアログ上部の年月日表記に曜日も表示する
  - [x] DatePickerダイアログ上部の年月日表記タップで直接入力で年月日を変更できるようにする
- [x] _showDeleteConfirmDialog（削除ダイアログ）の共通ウィジェット化
