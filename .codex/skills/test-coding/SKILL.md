---
name: test-coding
description: このリポジトリでユニットテストやインテグレーションテストを追加・修正するときの方針をまとめたスキル。テスト配置、命名、Mockito利用、TestException、Completerを使った非同期テスト制御に従ってテストコードを書きたいときに使う。
---

# Test Coding

このリポジトリでテストコードを追加・修正する際は、既存構成とテスト実行時の安定性を優先する。

## 基本方針

- ユニットテストのディレクトリ構成は`lib/`と同じにする
- テスト命名は`xxx_test.dart`とする
- 外部依存関係にはMockitoを使用したモックを使用する

## テストファイル

- ユニットテスト: `test/unit/`
- インテグレーションテスト: `test/integration/`

## テストベストプラクティス

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
