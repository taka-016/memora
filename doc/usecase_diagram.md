# ユースケース図

```mermaid
graph LR
    %% アクター定義
    User([ユーザー])
    
    %% システム境界
    subgraph "memora"
        UC1([家族などの単位でグループを作成する])
    end
    
    %% アクターとユースケースの関係
    User --> UC1