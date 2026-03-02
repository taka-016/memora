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


## 地図画面


## マップピンボトムシート


## 招待機能

- 招待コードで紐づけたmemberを更新した後、使用済み招待コードのレコードは削除する
- 作成から24時間経過した招待コードは無効とする

## グループイベント

- グループ年表のグループイベント行にgroup_eventsのデータを表示する
- 年表セルのタップでフリー入力メモのダイアログを開き、グループイベントを編集できるようにする
- グループイベントの仕様に合わせて設計および実装を更新する
  - ER図のgroup_events定義をフリー入力のみとする仕様に合わせて見直す
  - ER図の修正に合わせてエンティティやリポジトリ等を改修する

## DVCポイント計算画面

## デザイン


## 全体


## リファクタリング

- [ ] `lib/presentation/app/top_page.dart`: 違反内容 `domain/value_objects/auth_state.dart` を直接参照している。対応方針 認証状態は `application/dtos` の表示用モデルに置き換え、画面はユースケース経由の状態のみ参照する。
- [ ] `lib/presentation/features/auth/auth_guard.dart`: 違反内容 `domain/value_objects/auth_state.dart` と `infrastructure/factories/auth_service_factory.dart` を直接参照している。対応方針 `application/usecases` に認証状態取得・監視ユースケースを追加し、Factory依存をプレゼンテーション層から排除する。
- [ ] `lib/presentation/features/auth/login_page.dart`: 違反内容 `domain/value_objects/auth_state.dart` を直接参照している。対応方針 ログイン画面の分岐は `application/dtos` の認証状態DTOで扱う。
- [ ] `lib/presentation/features/auth/signup_page.dart`: 違反内容 `domain/value_objects/auth_state.dart` を直接参照している。対応方針 サインアップ画面の状態判定を認証状態DTO経由に変更する。
- [ ] `lib/presentation/features/group/group_edit_modal.dart`: 違反内容 `domain/entities/group/group.dart` を直接参照している。対応方針 画面入出力を `application/dtos/group/group_dto.dart` に統一し、ドメインエンティティはユースケース内で変換する。
- [ ] `lib/presentation/features/member/member_edit_modal.dart`: 違反内容 `domain/entities/member/member.dart` を直接参照している。対応方針 画面入出力を `application/dtos/member/member_dto.dart` に統一する。
- [ ] `lib/presentation/features/trip/route_info_view.dart`: 違反内容 `domain/value_objects/route_segment_detail.dart` を直接参照している。対応方針 経路表示用DTOを `application/dtos` に追加し、ユースケースがDTOを返す構成へ変更する。
- [ ] `lib/presentation/features/trip/route_memo_edit_bottom_sheet.dart`: 違反内容 `domain/value_objects/route_segment_detail.dart` を直接参照している。対応方針 ボトムシートの入力モデルを経路表示用DTOに置き換える。
- [ ] `lib/presentation/features/trip/select_visit_location_view.dart`: 違反内容 `domain/value_objects/location.dart` を直接参照している。対応方針 位置候補の受け渡しを `application/dtos` の位置DTOへ移行する。
- [ ] `lib/presentation/features/trip/trip_edit_modal.dart`: 違反内容 `domain/entities/trip/trip_entry.dart` `domain/exceptions/validation_exception.dart` `domain/value_objects/location.dart` を直接参照している。対応方針 画面の入力検証エラーと編集対象をDTO＋ユースケース戻り値に集約し、ドメイン例外の直接ハンドリングをやめる。
- [ ] `lib/presentation/features/trip/trip_management.dart`: 違反内容 `domain/entities/trip/trip_entry.dart` と `domain/value_objects/order_by.dart` を直接参照している。対応方針 一覧表示・並び順は `application/dtos/trip` 側のDTO/列挙へ移し、ユースケースAPIで抽象化する。
- [ ] `lib/presentation/notifiers/auth_notifier.dart`: 違反内容 `domain/value_objects/auth_state.dart` `domain/entities/account/user.dart` `infrastructure/factories/auth_service_factory.dart` を直接参照している。対応方針 認証Notifierは認証ユースケース群の戻り値DTOのみを扱い、インフラFactoryの生成責務を排除する。
- [ ] `lib/presentation/notifiers/current_member_notifier.dart`: 違反内容 `domain/value_objects/auth_state.dart` を直接参照している。対応方針 認証状態連携は認証状態DTOを介して行う。
- [ ] `lib/presentation/notifiers/location_notifier.dart`: 違反内容 `domain/value_objects/location.dart` `domain/value_objects/location_state.dart` `domain/services/current_location_service.dart` `infrastructure/services/geolocator_current_location_service.dart` を直接参照している。対応方針 現在地取得は `application/usecases` に委譲し、Notifierは位置DTOと画面状態DTOのみ扱う。
- [ ] `lib/presentation/shared/inputs/custom_search_bar.dart`: 違反内容 `domain/services/location_search_service.dart` と `domain/value_objects/location_candidate.dart` を直接参照している。対応方針 検索は場所検索ユースケースを新設して呼び出し、候補は検索結果DTOで受ける。
- [ ] `lib/presentation/shared/map_views/google_map_view_builder.dart`: 違反内容 `domain/value_objects/location.dart` を直接参照している。対応方針 ビュー生成の引数型を位置DTOへ変更する。
- [ ] `lib/presentation/shared/map_views/google_map_view.dart`: 違反内容 `domain/value_objects/location.dart` と `infrastructure/services/google_places_api_location_search_service.dart` を直接参照している。対応方針 マップ表示は位置DTOを受け取り、検索処理は場所検索ユースケース経由に統一する。
- [ ] `lib/presentation/shared/map_views/map_view_builder.dart`: 違反内容 `domain/value_objects/location.dart` を直接参照している。対応方針 抽象インターフェースの型を位置DTOへ置換する。
- [ ] `lib/presentation/shared/map_views/placeholder_map_view_builder.dart`: 違反内容 `domain/value_objects/location.dart` を直接参照している。対応方針 プレースホルダービューの引数型を位置DTOへ置換する。
- [ ] `lib/presentation/shared/sheets/pin_detail_bottom_sheet.dart`: 違反内容 `domain/services/nearby_location_service.dart` `domain/value_objects/location.dart` `infrastructure/services/google_places_api_nearby_location_service.dart` を直接参照している。対応方針 周辺検索はユースケース化し、ボトムシートは周辺候補DTOのみ扱う。

## 不具合修正
