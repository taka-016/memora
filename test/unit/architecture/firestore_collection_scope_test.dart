import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Firestoreルールはトップレベルのドキュメントだけを対象にする', () {
    final rules = File('firestore.rules').readAsStringSync();
    expect(_invalidPaths(rules), isEmpty, reason: 'Firestoreのサブコレクションは禁止です。');
  });

  test('入れ子と空白を含む再帰ワイルドカードを検出する', () {
    const rules = """
service cloud.firestore {
  match /databases/{database}/documents {
    match /groups/{groupId} {
      match /items/{itemId} {}
    }
    match /{collection}/{document = **} /* 注釈 */ {}
  }
}
""";
    expect(_invalidPaths(rules), [
      '/items/{itemId}',
      '/{collection}/{document = **}',
    ]);
  });
}

List<String> _invalidPaths(String rules) {
  final ignored = RegExp(
    r'''//[^\r\n]*|/\*[\s\S]*?\*/|'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"''',
  );
  final tokens = RegExp(r'\bmatch\s+(/(?:\{[^{}]+\}|[^\s{}])+)\s*\{|[{}]');
  var depth = 0;
  int? documentsDepth;
  final invalid = <String>[];
  for (final token in tokens.allMatches(rules.replaceAll(ignored, ' '))) {
    final path = token.group(1);
    if (path != null) {
      if (path == '/databases/{database}/documents') {
        documentsDepth = depth + 1;
      } else if (depth != documentsDepth ||
          path.substring(1).split('/').length != 2 ||
          RegExp(r'=\s*\*\*').hasMatch(path)) {
        invalid.add(path);
      }
      depth++;
    } else if (token.group(0) == '{') {
      depth++;
    } else if (token.group(0) == '}') {
      depth--;
    }
  }
  return invalid;
}
