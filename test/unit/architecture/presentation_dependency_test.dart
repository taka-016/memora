import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Presentation層はDomain層とInfrastructure層を直接参照しない', () {
    final violations = <String>[];
    final presentationDirectory = Directory('lib/presentation');

    for (final entity in presentationDirectory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      final source = entity.readAsStringSync();
      for (final forbiddenLayer in ['domain', 'infrastructure']) {
        if (source.contains("package:memora/$forbiddenLayer/")) {
          violations.add('${entity.path}: $forbiddenLayer');
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('Dialog表示前の単発取得はViewからUseCaseを直接実行する', () {
    final groupManagementSource = File(
      'lib/presentation/features/group/group_management.dart',
    ).readAsStringSync();
    final mapScreenSource = File(
      'lib/presentation/features/map/map_screen.dart',
    ).readAsStringSync();

    expect(
      groupManagementSource,
      matches(
        RegExp(
          r'ref\s*\.read\(\s*getManagedMembersUsecaseProvider\s*\)'
          r'\s*\.execute\(currentMember\)',
        ),
      ),
    );
    expect(
      groupManagementSource,
      isNot(contains('groupEditAvailableMembersProvider')),
    );
    expect(
      mapScreenSource,
      matches(
        RegExp(
          r'ref\s*\.read\(\s*getTripEntryByIdUsecaseProvider\s*\)'
          r'\s*\.execute\(trip\.id\)',
        ),
      ),
    );
    expect(mapScreenSource, isNot(contains('mapTripDetailProvider')));
  });
}
