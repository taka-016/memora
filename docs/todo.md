# ToDo List

## DB設計・リポジトリ・ユースケース・DTO・マッパー関連

## マップの表示


## トップ画面


## アカウント管理


## グループ管理


## メンバー管理画面

## グループ管理画面


## グループ年表画面

## 旅行管理画面
- 旅行編集画面から旅程画面へ遷移できるようにする
  - `TripEditExpandedSection`に旅程入力用のセクションを追加する
  - 旅行編集フォームに旅程画面への遷移ボタンを追加する
  - 旅程ボタンはタスクボタンと横並びにし、右端から順に「旅程」「タスク」に見える配置にする
  - ボタン名は「旅程」「タスク」にする
- 旅程画面を作成する
  - 旅行編集モーダル内に旅程画面を表示する
  - 旅程画面のヘッダーに「旅程」と閉じるボタンを表示する
  - 旅程画面内に旅程項目の一覧を表示する
  - 旅程項目の一覧には項目名、開始日時、終了日時、メモを表示する
  - 旅程画面内で旅程項目を追加できるようにする
  - 旅程項目の追加時は項目名、開始日時、終了日時、メモを入力できるようにする
  - 旅程項目を選択すると編集画面を表示し、項目名、開始日時、終了日時、メモを変更できるようにする
  - 旅程項目の追加、編集、削除をできるようにする
  - 旅程項目名が未入力の場合はエラーを表示し、追加・保存できないようにする
  - 終了日時が開始日時より前の場合はエラーを表示し、保存できないようにする
  - 旅程項目は開始日時の昇順で表示し、開始日時が未設定の項目は末尾に表示する
  - 開始日時が同じ場合は終了日時の昇順で表示する
  - 旅程画面を閉じる操作で旅行編集フォームへ戻れるようにする
- 旅程項目を旅行編集の下書き状態に反映する
  - `TripEditModal`の初期値比較と下書き更新対象に`itineraryItems`を含める
  - 旅程画面での追加・編集・削除を`draftTripEntry.itineraryItems`へ反映する
  - 既存旅行を開いたとき、`GetTripEntryByIdUsecase`で取得済みの旅程項目を表示する

## マップピンボトムシート

## 招待機能

## グループイベント

## メンバーイベント

## DVCポイント計算画面
- DVCの年月選択に`showDatePicker`を直接使用しているため、共通処理へ置き換える

## デザイン

## 全体

## リファクタリング
- 単純な手書きFake/MockをMockito生成モックへ置き換える
  - `test/unit/application/usecases/account/get_current_user_usecase_test.dart`の手書き`MockAuthService`を`@GenerateMocks([AuthService])`へ置き換える
  - DVCユースケースの単純な手書きRepository/QueryService Fakeを生成モックへ置き換える
    - `test/unit/application/usecases/dvc/get_dvc_point_contracts_usecase_test.dart`
    - `test/unit/application/usecases/dvc/get_dvc_limited_points_usecase_test.dart`
    - `test/unit/application/usecases/dvc/get_dvc_point_usages_usecase_test.dart`
    - `test/unit/application/usecases/dvc/delete_dvc_limited_point_usecase_test.dart`
    - `test/unit/application/usecases/dvc/delete_dvc_point_usage_usecase_test.dart`
    - `test/unit/application/usecases/dvc/save_dvc_limited_point_usecase_test.dart`
    - `test/unit/application/usecases/dvc/save_dvc_point_usage_usecase_test.dart`
    - `test/unit/application/usecases/dvc/save_dvc_point_contracts_usecase_test.dart`
  - `test/unit/presentation/shared/map_views/google_map_view_test.dart`の`FakeGetCurrentLocationUsecase`と`FakeSearchLocationsUsecase`を生成モックへ置き換える
  - `test/unit/presentation/shared/inputs/custom_search_bar_test.dart`の`FakeSearchLocationsUsecase`と`ThrowingSearchLocationsUsecase`を生成モックへ置き換える
  - `test/unit/presentation/features/trip/task_view_test.dart`の`FakeTaskQueryService`と`FailingTaskQueryService`を生成モックへ置き換える
  - `test/unit/presentation/features/trip/trip_edit_modal_test.dart`の`FakeGetNearbyLocationNameUsecase`を生成モックへ置き換える

## 不具合修正
