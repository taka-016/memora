---
name: test-coding
description: このリポジトリでテストコードを扱うときに必ず使うスキル。追加、修正、整理などテストまわりの作業を進めるときに使う。
---

# Test Coding

このリポジトリでテストコードを書きたいときは、このスキルを使って既存構成とテスト実行時の安定性を優先する。

## 基本方針

- ユニットテストのディレクトリ構成は`lib/`と同じにする
- テスト命名は`xxx_test.dart`とする
- 外部依存関係にはMockitoを使用したモックを使用する
- 外部依存や抽象インターフェースを差し替えるテストでは、手書きFake/MockよりもMockitoの`@GenerateMocks`または`@GenerateNiceMocks`で生成したモックを優先する
- 実装コードより先に、失敗するテストを書くか既存テストへ失敗ケースを追加する。

## テストファイル

- ユニットテスト: `test/unit/`
- インテグレーションテスト: `test/integration/`

## テストベストプラクティス

- 生成モックの扱い: `**/*.mocks.dart`は生成物をコミットしないために`.gitignore`で除外しているだけであり、生成モックの作成や利用を禁止する意図ではない。生成モックが必要な場合は、テストファイルに生成アノテーションと`*.mocks.dart`のimportを追加し、`dart run build_runner build --delete-conflicting-outputs`で生成してからテストを実行する。生成された`*.mocks.dart`は通常コミットしない

- Fakeの使い分け: 状態遷移やProviderの生存期間など、テスト固有の振る舞いを小さく表現するFakeは必要に応じて使用してよい。単純な戻り値、例外、呼び出し検証で足りる場合は生成モックへ寄せる

- テストでの例外発生: テストで例外を発生させる場合は、必ず`test/helpers/test_exception.dart`の`TestException`を使用すること。`TestException`はログ出力を抑制するため、テスト実行時のノイズを減らすことができる

  ```dart
  // ❌ 避けるべき方法
  when(mockUseCase.execute()).thenThrow(Exception('エラーメッセージ'));

  // ✅ 推奨する方法
  import '../../../helpers/test_exception.dart';

  when(mockUseCase.execute()).thenThrow(TestException('エラーメッセージ'));
  ```

- 非同期テストの制御: `Future.delayed`を使った待機は避ける。環境によって不安定になるため、`Completer`を使用してテストコードが非同期処理のタイミングを制御する

  ```dart
  // ❌ 避けるべき方法
  when(mockUseCase.execute()).thenAnswer((_) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return result;
  });

  // ✅ 推奨する方法
  final completer = Completer<Result>();
  when(mockUseCase.execute()).thenAnswer((_) => completer.future);
  // テストコードで完了タイミングを制御
  completer.complete(result);
  ```
