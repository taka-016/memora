# ER図

```mermaid
erDiagram
    trip_entries {
        string id PK
        string groupId FK "NOT NULL"
        string name
        number year "NOT NULL"
        timestamp startDate
        timestamp endDate
        string memo
    }
    locations {
        string id PK
        string tripId FK
        string groupId FK
        string name
        number latitude "NOT NULL"
        number longitude "NOT NULL"
    }
    tasks {
        string id PK
        string tripId FK "NOT NULL"
        number orderIndex "NOT NULL"
        string parentTaskId FK
        string name "NOT NULL"
        boolean isCompleted "NOT NULL"
        timestamp dueDate
        string memo
        string assignedMemberId FK
    }
    itinerary_items {
        string id PK
        string tripId FK "NOT NULL"
        string name "NOT NULL"
        timestamp startDateTime
        timestamp endDateTime
        string memo
        string locationId FK
    }
    groups {
        string id PK
        string ownerId FK "NOT NULL"
        string name "NOT NULL"
        string memo
    }
    group_members {
        string id PK
        string groupId FK "NOT NULL"
        string memberId FK "NOT NULL"
        boolean isAdministrator "NOT NULL"
        number orderIndex "NOT NULL"
    }
    group_events {
        string id PK
        string groupId FK "NOT NULL"
        number year "NOT NULL"
        string memo "NOT NULL"
    }
    members {
        string id PK
        string accountId
        string ownerId FK
        string hiraganaFirstName
        string hiraganaLastName
        string kanjiFirstName
        string kanjiLastName
        string firstName
        string lastName
        string displayName "NOT NULL"
        string type
        timestamp birthday
        string gender
        string email
        string phoneNumber
    }
    member_events {
        string id PK
        string memberId FK "NOT NULL"
        number year "NOT NULL"
        string memo "NOT NULL"
    }
    member_invitations {
        string id PK
        string inviteeId FK "NOT NULL"
        string inviterId FK "NOT NULL"
        string invitationCode "NOT NULL"
    }
    dvc_point_contracts {
        string id PK
        string groupId FK "NOT NULL"
        string contractName "NOT NULL"
        timestamp contractStartYearMonth "NOT NULL"
        timestamp contractEndYearMonth "NOT NULL"
        number useYearStartMonth "NOT NULL"
        number annualPoint "NOT NULL"
    }
    dvc_limited_points {
        string id PK
        string groupId FK "NOT NULL"
        timestamp startYearMonth "NOT NULL"
        timestamp endYearMonth "NOT NULL"
        number point "NOT NULL"
        string memo
    }
    dvc_point_usages {
        string id PK
        string groupId FK "NOT NULL"
        timestamp usageYearMonth "NOT NULL"
        number usedPoint "NOT NULL"
        string memo
    }
    calendar_events {
        string id PK
        string groupId FK "NOT NULL"
        string labelId FK "NOT NULL"
        string title "NOT NULL"
        timestamp startDateTime "NOT NULL"
        timestamp endDateTime "NOT NULL"
        boolean isAllDay "NOT NULL"
        string recurrenceRule
        string timeZone
    }
    calendar_event_overrides {
        string id PK
        string eventId FK "NOT NULL"
        timestamp originalStartDateTime "NOT NULL"
        boolean isCancelled "NOT NULL"
        string title
        timestamp startDateTime
        timestamp endDateTime
        boolean isAllDay
        string labelId FK
    }
    calendar_labels {
        string id PK
        string groupId FK "NOT NULL"
        string name "NOT NULL"
        string color "NOT NULL、#RRGGBB"
        string textColor "NOT NULL、#RRGGBB"
        integer sortOrder "NOT NULL、0以上"
    }
    google_calendar_connections {
        string memberId PK, FK
        string googleAccountId "NOT NULL"
    }
    google_calendar_selections {
        string memberId PK, FK
        string calendarId PK
    }

    trip_entries ||--o{ locations : "id → tripId"
    trip_entries ||--o{ tasks : "id → tripId"
    trip_entries ||--o{ itinerary_items : "id → tripId"
    tasks ||--o{ tasks : "id → parentTaskId"
    tasks ||--|| members : "assignedMemberId → id"
    locations |o--o{ itinerary_items : "id → locationId"
    groups ||--o{ group_members : "id → groupId"
    groups ||--o{ group_events : "id → groupId"
    groups ||--o{ trip_entries : "id → groupId"
    groups ||--o{ locations : "id → groupId"
    group_members ||--|| members : "memberId → id"
    members ||--o{ member_events : "id → memberId"
    members ||--o{ members : "id → ownerId"
    members ||--o{ groups : "id → ownerId"
    members ||--o{ member_invitations : "id → inviteeId"
    members ||--o{ member_invitations : "id → inviterId"
    groups ||--o{ dvc_point_contracts : "id → groupId"
    groups ||--o{ dvc_limited_points : "id → groupId"
    groups ||--o{ dvc_point_usages : "id → groupId"
    groups ||--o{ calendar_events : "id → groupId"
    groups ||--o{ calendar_labels : "id → groupId"
    calendar_labels ||--o{ calendar_events : "id → labelId"
    calendar_events ||--o{ calendar_event_overrides : "id → eventId"
    calendar_labels |o--o{ calendar_event_overrides : "id → labelId"
    members ||--o| google_calendar_connections : "id → memberId"
    google_calendar_connections ||--o{ google_calendar_selections : "memberId → memberId"
    externally_managed_accounts ||--|| members : "id → accountId"
```

## オフラインモードの物理スキーマ

上図は共通の業務モデルとFirestoreの関連を示す。SQLiteの物理定義と制約・indexは[`offline_schema.drift`](../lib/infrastructure/database/offline_schema.drift)、保存形式とマイグレーションの方針は[ADR-002](adr.md#adr-002-オフラインデータをsqliteへ保存する)を参照。

## 繰り返し予定の保存と展開

- 繰り返しルールは日・週・月・年のRRULEを保存する。正の間隔、週の複数曜日、月の日付または第1〜第5／最終の曜日、初回を含む正の回数、終了日を含むUNTILを扱う。COUNTとUNTILの同時指定、開始日前の終了条件、開始日と一致しない曜日・月の日付指定、未対応のプロパティは拒否する。
- 時刻付き系列の開始・終了は実時刻、`timeZone`はIANA IDとして保存する。時刻付きのUNTILはUTC日時形式に限定し、実時刻で比較する。終日はUTCの年月日だけを保存・比較し、終了日を含める。毎月31日や毎年2月29日、夏時間で存在しない時刻はその回をスキップし、回数に含めない。重複する時刻は早い方を採用し、初回に遅い方を指定した入力は保存前に拒否する。各回の終了は初回の経過時間を保つ。
- 個別回のキーは元の開始日時（終日は元の日付）とし、移動しても変更しない。取消しにはキーだけを保存し、変更にはタイトル・期間・終日区分・色ラベルをすべて保存する。系列に存在しない回や重複キー、別グループの色ラベルは拒否する。系列のルールと個別回は同じ保存要求で置き換え、不適合な上書きを含む変更は全体を拒否する。
- Firestoreでは`calendar_events`の親ドキュメント内に、`overrides`を色ラベルID別の配列として保存する。配列内に色ラベルIDを保存せず、読取時にそのキーを各回へ割り当てる。取消しの元開始日時は`cancelledOccurrences`に保存する。`referencedLabelIds`は親と上書きが参照するラベルの重複なし一覧で、各ラベルの`eventCount`はそのラベルを参照する系列数を表す。親・上書き・全ラベルの参照数を同じトランザクションで更新し、ルールでも参照の一致、グループ、増減を検証する。ルールのドキュメント読取数制限内で系列の保存・削除を検証するため、オンラインの1系列が参照できるラベルは3種類までとし、一括更新も変更前後の参照ラベルの合計を3種類までに制限する。上限を超える更新は保存前に理由を示して拒否する。さらにFirestoreのトランザクション制限を超える変更は全体が失敗し、変更前を維持する。
- SQLiteはスキーマバージョン5の`calendar_events`と`calendar_event_overrides`を単一トランザクションで保存する。親と元開始日時の組を主キーにし、グループ・ラベルの外部キー制約を維持する。親の削除で個別回も削除する。バックアップ・復元には両テーブルを含め、復元確認前に繰り返し設定と上書きの整合性を検証する。旧スキーマは移行や再作成を行わず拒否する。
- 各回は保存せず、月表示と前後の日付に重なる回だけを展開する。グループの全系列と保存済みの上書きを取得するため、別月へ移動した回も変更後の期間に表示し、元の回は表示しない。月切替では取得済みの系列から再展開する。登録・編集画面でプリセットまたはカスタムの繰り返しを設定し、設定の要約を表示する。編集・削除では「この予定のみ」「この予定とこれ以降」「すべての予定」を選択する。個別回は元開始日時をキーに上書きまたは取消しを保存する。「これ以降」は元開始日時を境に元系列を直前で終了し、新系列を同じトランザクションで保存する。初回からの変更は元系列を置き換える。系列全体の日時変更は選択回からの差分を初回へ適用する。一括変更・分割は対象範囲の上書きを解除し、対象範囲外の上書きを維持する。確認画面に解除・引継ぎ件数を表示する。保存時に元系列の内容を照合し、他の編集と競合した場合は全体を拒否して再取得を案内する。
