# memora

## env.g.dartの生成
1. .envファイルをプロジェクトルートに作成し、必要な環境変数を設定します。
   - 使用する環境変数は.env.exampleを参考にしてください。
2. `memora`プロジェクトのルートディレクトリで以下のコマンドを実行して、`env.g.dart`ファイルを生成します。
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```
