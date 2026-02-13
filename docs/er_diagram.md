# ER図

```mermaid
erDiagram
    trip_entries {
        string id PK
        string groupId FK "NOT NULL"
        string tripName
        number tripYear "NOT NULL"
        timestamp tripStartDate
        timestamp tripEndDate
        string tripMemo
    }
    pins {
        string id PK
        string pinId UK "NOT NULL"
        string tripId FK
        string groupId FK
        number latitude "NOT NULL"
        number longitude "NOT NULL"
        string locationName
        timestamp visitStartDate
        timestamp visitEndDate
        string visitMemo
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
    }
    group_events {
        string id PK
        string groupId FK "NOT NULL"
        string type "NOT NULL"
        string name
        timestamp startDate "NOT NULL"
        timestamp endDate "NOT NULL"
        string memo
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
        string passportNumber
        string passportExpiration
    }
    member_events {
        string id PK
        string memberId FK "NOT NULL"
        string type "NOT NULL"
        string name
        timestamp startDate "NOT NULL"
        timestamp endDate "NOT NULL"
        string memo
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

    trip_entries ||--o{ pins : "id → tripId"
    trip_entries ||--o{ tasks : "id → tripId"
    tasks ||--o{ tasks : "id → parentTaskId"
    tasks ||--|| members : "assignedMemberId → id"
    groups ||--o{ group_members : "id → groupId"
    groups ||--o{ group_events : "id → groupId"
    groups ||--o{ trip_entries : "id → groupId"
    groups ||--o{ pins : "id → groupId"
    group_members ||--|| members : "memberId → id"
    members ||--o{ member_events : "id → memberId"
    members ||--o{ members : "id → ownerId"
    members ||--o{ groups : "id → ownerId"
    members ||--o{ member_invitations : "id → inviteeId"
    members ||--o{ member_invitations : "id → inviterId"
    groups ||--o{ dvc_point_contracts : "id → groupId"
    groups ||--o{ dvc_limited_points : "id → groupId"
    groups ||--o{ dvc_point_usages : "id → groupId"
    externally_managed_accounts ||--|| members : "id → accountId"
```
