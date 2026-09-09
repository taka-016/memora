import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/services/local_current_member_resolver.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('memora-identity-test-');
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('初回に利用者と本人を保存し別インスタンスから同じ本人を復元する', () async {
    final resolver = LocalCurrentMemberResolver(
      directory: () async => directory,
    );
    final results = await Future.wait([resolver.resolve(), resolver.resolve()]);
    expect(results[0], results[1]);
    final member = results.first;
    expect(member.id, isNotEmpty);
    expect(member.accountId, isNotEmpty);
    expect(member.displayName, '本人');
    final restored = await LocalCurrentMemberResolver(
      directory: () async => directory,
    ).resolve();
    expect(restored, member);
  });

  test('破損した保存内容を新しい利用者で上書きせず修復後に再試行できる', () async {
    final resolver = LocalCurrentMemberResolver(
      directory: () async => directory,
    );
    final member = await resolver.resolve();
    final file = File('${directory.path}/offline_current_member.json');
    final saved = await file.readAsString();
    await file.writeAsString('{}');
    await expectLater(resolver.resolve(), throwsFormatException);
    expect(await file.readAsString(), '{}');
    await file.writeAsString(saved);
    expect(await resolver.resolve(), member);
  });
}
