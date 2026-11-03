# ユースケース図

主要な利用目的と利用できるアプリモードを示す。詳細な仕様と受け入れ条件は[ユーザーストーリー](user_stories.md)を参照。

```mermaid
graph LR
    User([ユーザー])

    subgraph memora
        direction TB

        subgraph Online[オンラインのみ]
            Auth([認証する])
            Invite([メンバーを招待・参加する])
            Map([地図で旅行記録を管理する])
        end

        subgraph Common[オンライン・オフライン共通]
            Group([グループを管理する])
            Member([メンバーを管理する])
            DeleteGroup([グループを削除し親を退避・関連データを保持する])
            DeleteMember([メンバーを削除し親を退避・関連データを保持する])
            Timeline([年表で記録を管理する])
            Trip([旅行を管理する])
            Dvc([DVCポイントを管理する])
            DvcContract([契約を管理する])
            DvcUsage([契約を選択してポイントを利用する])
            DvcLimited([契約へ期間限定ポイントを登録する])
            Widget([ウィジェットで旅程を確認する])
        end

        subgraph Offline[オフラインのみ]
            Backup([データをバックアップ・復元する])
        end
    end

    User --> Auth
    User --> Invite
    User --> Map
    User --> Group
    User --> Member
    Group --> DeleteGroup
    Member --> DeleteMember
    User --> Timeline
    User --> Trip
    User --> Dvc
    Dvc --> DvcContract
    Dvc --> DvcUsage
    Dvc --> DvcLimited
    User --> Widget
    User --> Backup
```

グループ・メンバーの削除は、親の全情報を元のIDで専用の削除済み保存先へ移し、通常の保存先から除く。退避と元データ削除は原子的に行い、関連データ・所属・担当は保持する。退避した親は通常画面とAndroidウィジェットで表示・選択・操作できず、削除済み一覧や復活操作は提供しない。
