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
- タスク編集ボトムシートの締切日DatePickerは、締切日未設定時に旅行開始日の年月を初期ページにする
- タスク編集ボトムシートの締切日は、カレンダーアイコンを表示し、クリアボタンを入力枠内に配置して旅行期間の入力UIと揃える
- ピン詳細ボトムシートの訪問開始日DatePickerは、訪問開始日未設定時に旅行開始日の年月を初期ページにする
- ピン詳細ボトムシートの訪問終了日DatePickerは、訪問終了日未設定時に訪問開始日があればその年月、なければ旅行開始日の年月を初期ページにする

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
