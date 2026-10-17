# Architecture Decision Records

今後も維持するアーキテクチャ上の判断を、機能領域を問わず1件ずつ記録する。新しい判断は既存の最大番号に続く連番とし、`adr-連番-短い英語タイトル.md`（例: `adr-014-example-decision.md`）の形式でこのディレクトリへ追加する。連番は3桁のゼロ埋め、英語タイトルは小文字の単語をハイフンで区切る。各ADRには「ステータス」「決定日」「コンテキスト」「検討した選択肢」「決定事項」「決定理由」「結果」を記載する。実装の詳細は、各ADRで示すコードやスキーマを正本とする。

決定事項と決定理由は同じADRファイル内の別セクションで管理する。「決定日」には合意した日付（不明な場合は「不明」）、「コンテキスト」には前提・背景、「検討した選択肢」には実際に検討した案と採否、「決定事項」には採用する方針・保証範囲、「決定理由」には選択の根拠・比較・トレードオフ、「結果」には決定による影響を記載する。検討した選択肢が不明な場合は、そのセクションを省略する。理由・選択肢・決定日は推測で補わない。ADR本文には判断そのものを記載し、調査経緯や資料の確認状況などの補足は記載しない。

ADRの追加・追記はユーザーから明示的に指示された場合にのみ行う。

- [ADR-001: アプリモードごとにComposition Rootで依存実装を選択する](adr-001-app-mode-composition-root.md)
- [ADR-002: オフラインデータをSQLiteへ保存する](adr-002-offline-sqlite-storage.md)
- [ADR-003: オフラインデータを暗号化した論理バックアップで保存・復元する](adr-003-encrypted-offline-backup.md)
- [ADR-004: グループの予定と個人の外部予定を分離して扱う](adr-004-group-and-external-calendars.md)
- [ADR-005: 業務データの登録はアプリ経由のみを前提とする](adr-005-app-only-data-registration.md)
- [ADR-006: 予定のタイムゾーンをデータに保持し画面入力を求めない](adr-006-calendar-time-zone.md)
- [ADR-007: グループ削除時の同時追加による不要データの残存は現時点で対策しない](adr-007-defer-group-deletion-race-handling.md)
- [ADR-008: グループとメンバーは削除済み保存先へ移動し関連データを残す](adr-008-archive-groups-and-members.md)
- [ADR-009: オンラインの保存成功はサーバーでの書き込み完了で判定する](adr-009-server-confirmed-writes.md)
- [ADR-010: オンラインの更新排他は整数バージョンとSecurity Rulesで行う](adr-010-version-based-concurrency-control.md)
- [ADR-011: 親子の編集は集約単位で競合を検出し原子的に保存する](adr-011-atomic-aggregate-updates.md)
- [ADR-012: オンラインの削除も期待バージョンを照合してから行う](adr-012-version-checked-deletion.md)
- [ADR-013: 通常の取得結果で編集し確認用の再取得を追加しない](adr-013-edit-without-refetching.md)
