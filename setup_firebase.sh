#!/bin/bash

set -e  # エラーが発生したら即座に終了

echo "Firebase セットアップスクリプト"
echo "================================"

# Firebase CLIがインストールされているかチェック
if ! command -v firebase &> /dev/null; then
    echo "Firebase CLIがインストールされていません。"
    echo "インストールしますか？ (y/n)"
    read -r answer
    if [ "$answer" = "y" ]; then
        npm install -g firebase-tools || { echo "インストールに失敗しました"; exit 1; }
    else
        echo "Firebase CLIをインストールしてから再実行してください。"
        exit 1
    fi
fi

# FlutterFire CLIがインストールされているかチェック
if ! dart pub global list | grep -q flutterfire_cli; then
    echo "FlutterFire CLIをインストールしています..."
    dart pub global activate flutterfire_cli || { echo "FlutterFire CLIのインストールに失敗しました"; exit 1; }
fi

# ログインチェック
if ! firebase projects:list &> /dev/null; then
    echo "Firebaseにログインしてください..."
    echo "Gemini機能とデータ収集は両方ともNoを選択してください"
    firebase login || { echo "ログインに失敗しました"; exit 1; }
fi

# Flutter Firebaseの設定確認
if [ ! -f "lib/firebase_options.dart" ]; then
    echo "Firebase設定ファイルが見つかりません。FlutterFire CLIで設定します..."
    dart pub global run flutterfire_cli:flutterfire configure || { echo "Firebase設定に失敗しました"; exit 1; }
fi

# firebase.jsonにFirestoreインデックス設定を追加
if [ -f "firebase.json" ] && ! grep -q '"indexes"' firebase.json; then
    echo "Firestoreインデックス設定を追加しています..."
    # 一時ファイルでjsonを更新
    if command -v jq &> /dev/null; then
        jq '.firestore.indexes = "firestore.indexes.json"' firebase.json > firebase.json.tmp && mv firebase.json.tmp firebase.json
        echo "✓ Firestoreインデックス設定を追加しました"
    else
        echo "エラー: jqがインストールされていません。"
        echo "jqをインストールしてから再実行してください。"
        exit 1
    fi
fi

# プロジェクト設定
echo "プロジェクトを設定しています..."
echo "エイリアス名を聞かれたらdefaultまたはmemoraを入力してください"
firebase use --add || { echo "プロジェクト設定に失敗しました"; exit 1; }

# インデックスデプロイ
echo "Firestoreインデックスをデプロイしています..."
firebase deploy --only firestore:indexes || { echo "インデックスデプロイに失敗しました"; exit 1; }

echo "Firestore インデックスを同期しています..."
firebase firestore:indexes > "firestore.indexes.json" || { echo "インデックス同期に失敗しました"; exit 1; }

echo ""
echo "セットアップ完了！"