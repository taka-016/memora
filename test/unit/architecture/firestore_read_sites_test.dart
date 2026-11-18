import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FirestoreのSDK取得は登録済み計測箇所だけを経由する', () {
    final registry = jsonDecode(
      File('test/fixtures/firestore_read_regression/read_sites.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final listed = <String, String>{};
    for (final raw in registry['sites'] as List) {
      final site = raw as Map<String, dynamic>;
      final id = site['id'] as String;
      expect(listed.containsKey(id), isFalse, reason: '取得箇所IDが重複しています: $id');
      listed[id] = site['file'] as String;
    }
    final actual = <String, String>{};
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      if (file.path.endsWith('/firestore_measured_reads.dart')) continue;
      final source = file.readAsStringSync();
      if (!source.contains(
        "import 'package:cloud_firestore/cloud_firestore.dart';",
      )) {
        continue;
      }
      final rawReads = RegExp(r'\.(get|snapshots)\(')
          .allMatches(source)
          .where((match) {
            final prefix = source.substring(0, match.start);
            return !prefix.endsWith('context');
          })
          .toList();
      expect(rawReads, isEmpty, reason: '${file.path}に未計測のSDK読み取りがあります');
      for (final match in RegExp(
        r"\.measured(Get|Snapshots)\(\s*'([^']+)'",
      ).allMatches(source)) {
        final id = match.group(2)!;
        expect(actual.containsKey(id), isFalse, reason: '取得箇所IDが重複しています: $id');
        actual[id] = file.path;
      }
    }
    expect(actual, listed, reason: 'SDK読み取り箇所と取得経路一覧が一致しません');
  });
}
