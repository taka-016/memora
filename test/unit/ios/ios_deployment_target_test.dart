import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _xcodeProjectPath = 'ios/Runner.xcodeproj/project.pbxproj';

void main() {
  group('iOS Deployment Target', () {
    test('全ビルド構成でworkmanagerが要求するiOS 14.0以上を指定する', () {
      final project = File(_xcodeProjectPath).readAsStringSync();
      final deploymentTargets = RegExp(
        r'IPHONEOS_DEPLOYMENT_TARGET = ([\d.]+);',
      ).allMatches(project);

      expect(deploymentTargets, hasLength(3));
      expect(
        deploymentTargets.map((match) => double.parse(match.group(1)!)),
        everyElement(greaterThanOrEqualTo(14.0)),
      );
    });
  });
}
