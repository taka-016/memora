---
name: maintain-flutter-dependencies
description: memoraのFlutter SDK、Dart/Flutterパッケージ、devcontainer、Android SDK・NDK、Gradle Wrapper、Android Gradle Plugin、Kotlin、JDKなどの開発・ビルド依存をまとめて調査、更新、互換性修正、検証、PR作成まで行う。`packages have newer versions incompatible with dependency constraints`を解消したいとき、依存関係が古くなったとき、FlutterやAndroidビルド環境を一括更新したいときに使う。
---

# Flutter依存関係メンテナンス

Flutter、パッケージ、コンテナ、Androidビルドツールを一つの互換性単位として更新する。最新版へ機械的に揃えず、公式の互換条件と実際のビルド結果を根拠に、安全に採用できる最新構成へ進める。

## 基本方針

- このスキルによる依存保守だけを目的とする作業では、`docs/todo.md` の確認と更新を不要とし、依存保守自体をtodoへ追加しない。
- 作業開始時に `coding-preparation`、アプリやテストのコード修正時に `coding` と `test-coding`、完了時に `coding-completion` を使用する。
- 現在が `main` なら `chore/` で始まる作業ブランチを作成する。
- ユーザーが対象を限定していない限り、Flutter、Dartパッケージ、devcontainer、Androidビルド環境を一括で点検する。
- バージョン番号だけを根拠なく揃えない。Flutterと各ツールが公式にサポートする組み合わせを採用する。
- `dependency_overrides`、解決戦略による強制、上限の無条件撤廃で競合を隠さない。必要な場合は理由と除去条件をユーザーに示し、了承を得る。
- 推移依存の最新版未採用だけを理由に、直接依存を追加しない。
- 既存の未コミット差分を変更、破棄、巻き戻ししない。

## 1. 現状を記録する

次を確認し、更新前の状態を短く整理する。

```bash
git status --short --branch
flutter --version
dart --version
flutter doctor -v
flutter pub outdated
```

バージョン指定箇所を `rg` で横断確認する。最低限、次を対象にする。

- `.devcontainer/Dockerfile`
  - Ubuntu、Flutter、JDK、Android command-line tools、platform、build-tools、NDK
- `pubspec.yaml` と `pubspec.lock`
  - Dart/Flutter SDK制約、直接依存、開発依存
- `packages/**/pubspec.yaml`
  - ローカルパッケージのSDK制約と依存
- `android/settings.gradle.kts`
  - Android Gradle Plugin、built-in Kotlin、Compose Compiler、Google Services
- `android/gradle/wrapper/gradle-wrapper.properties`
  - Gradle Wrapper
- `android/app/build.gradle.kts`
  - Java、Kotlin JVM target、NDK、compileSdk、targetSdk、ネイティブ依存

更新前に `./check.sh` と `flutter build apk --debug` を実行する。既存の失敗やログがある場合は更新起因と混同せず、結果を記録してから進める。

## 2. 更新候補と互換性を調査する

情報が変化するため、毎回最新の公式資料を確認する。技術情報の検索には一次情報だけを使う。

- Flutter/Dart: Flutter公式リリースノート、移行ガイド、Dart SDK情報
- Dart/Flutterパッケージ: `flutter pub outdated`、pub.dev、公式リポジトリのchangelog・migration guide
- Android: Android DevelopersのAGPリリースノートと互換表、Gradle公式互換情報、Kotlin公式情報
- Docker/devcontainer: 利用しているベースイメージと各配布元の公式情報

Flutter/DartパッケージのAPIや移行方法を調べる場合は、AGENTS.mdに従ってContext7でライブラリIDを解決し、公式ドキュメントを取得する。Context7に対象がない場合は公式サイトや公式リポジトリを使う。

特に次の組み合わせを一体で判断する。

- Flutter SDK ↔ Dart SDK ↔ `pubspec.yaml` のSDK制約
- Flutter SDK ↔ Android Gradle Plugin
- Android Gradle Plugin ↔ Gradle Wrapper ↔ JDK
- Android Gradle Plugin ↔ built-in Kotlin ↔ Compose Compiler
- Flutter/プラグイン ↔ compileSdk・targetSdk・minSdk・NDK
- `.devcontainer/Dockerfile` のJDK・Android SDK・NDK ↔ Androidプロジェクト設定

最新版同士が非互換なら、プロジェクト全体で検証できる最も新しい互換構成を選ぶ。保留する更新は、上流の制約と再検討条件を明記する。

## 3. 依存関係を更新する

影響源に近い順で更新する。

1. `.devcontainer/Dockerfile` のFlutter SDKを更新する。
2. Dart/Flutter SDK制約を、新しいFlutter同梱SDKと整合させる。
3. `flutter pub upgrade --major-versions` を使い、直接依存と開発依存の制約およびlockfileを更新する。
4. `flutter pub outdated` を再実行し、残件を確認する。
5. 必要なAndroidビルド環境を互換性マトリクスに沿って更新する。
6. devcontainerとAndroidプロジェクトで重複指定するNDK、JDKなどを一致させる。

一度に原因を見失わないよう、Flutter/SDK、Dartパッケージ、Androidツールの境界ごとに差分とコマンド結果を確認する。`pubspec.lock` はアプリケーションの再現可能なビルドに必要なため更新対象に含める。

`flutter pub outdated` の残件は次に分類する。

- 直接依存の制約を安全に更新できる: 更新する。
- 別の直接依存が古い推移依存を要求している: 上位パッケージの更新可否を調べる。
- Flutter/Dart SDKがバージョンを固定している: SDKの公式制約として記録する。
- 上流がまだ互換版を提供していない: 無理に解決せず、パッケージ名と制約元をPRへ記載する。

## 4. 破壊的変更へ対応する

コンパイル、解析、テスト、Androidビルドの失敗を一件ずつ解消する。API変更が必要なら公式の移行ガイドを根拠に、既存設計を保つ最小変更に留める。

- アプリの振る舞いを変える修正では、`coding` と `test-coding` に従って先に失敗テストを追加する。
- ビルド設定だけの互換性修正では、失敗した解析またはビルドコマンドを再現条件として扱う。
- Presentation層の依存方向など、既存アーキテクチャの制約を崩さない。
- 非推奨APIを別の非推奨APIへ置き換えない。
- 更新と無関係なリファクタリングを混ぜない。

Flutter更新後のAndroidテンプレート差分が必要なら、同じFlutter版で作成した一時プロジェクトと比較する。ただし既存のAndroid固有実装をテンプレートで上書きしない。

## 5. 検証する

変更後のFlutter版で、次を順に実行する。

```bash
flutter pub get
flutter pub outdated
./check.sh
flutter build apk --debug
```

加えて次を確認する。

- `./check.sh` にエラー、予期しないExceptionログ、エラーログがない。
- Androidビルドが更新後のGradle Wrapper、AGP、Kotlin、JDK、SDK、NDKを実際に使用して成功する。
- Dockerが利用可能なら `.devcontainer/Dockerfile` をビルドし、少なくともFlutterとAndroid SDKの導入が成功する。
- Dockerをビルドできない環境では、Dockerfileの指定値とAndroid側の整合を静的に確認し、未実施の検証を明記する。
- 署名情報が利用できる場合は `./tools/ci/release_android_apk.sh` も実行する。利用できない場合はdebug APK成功をAndroid検証とする。

Flutterを一時SDKで検証した場合も、最終的なコマンド結果が `.devcontainer/Dockerfile` に指定した版と一致することを確認する。検証失敗を残したまま完了しない。

## 6. コミット・PR・報告を完了する

`coding-completion` とAGENTS.mdに従って、関連ファイルだけをコミットしてpushし、GitHub MCPでPRを作成する。`gh` CLIは使わない。

PRと最終報告には次を含める。

- Flutter/Dart、主要パッケージ、AGP、Gradle、Kotlin、JDK、Android SDK/NDKの更新前後
- 破壊的変更に対するコード・設定修正
- 実行した検証と結果
- `flutter pub outdated` に残るパッケージと、更新できない具体的な理由
- Dockerビルドやrelease APKなど未実施の検証と理由

更新対象がなく、既に安全な最新互換構成だった場合は、不要な差分やPRを作らず調査結果だけを報告する。
