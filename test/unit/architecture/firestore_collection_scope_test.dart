import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Firestoreルールはトップレベルのドキュメントだけを対象にする', () {
    final rules = File('firestore.rules').readAsStringSync();
    final tokens = RegExp(
      r'''//[^\r\n]*|/\*[\s\S]*?\*/|'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"|\bmatch\s+(/[^\s]+)\s*\{|[{}]''',
    );
    var depth = 0;
    int? documentsDepth;
    final invalid = <String>[];
    for (final token in tokens.allMatches(rules)) {
      final path = token.group(1);
      if (path != null) {
        if (path == '/databases/{database}/documents') {
          documentsDepth = depth + 1;
        } else if (depth != documentsDepth ||
            path.substring(1).split('/').length != 2 ||
            path.contains('=**')) {
          invalid.add(path);
        }
        depth++;
      } else if (token.group(0) == '{') {
        depth++;
      } else if (token.group(0) == '}') {
        depth--;
      }
    }
    expect(invalid, isEmpty, reason: 'Firestoreのサブコレクションは禁止です。');
  });
}
