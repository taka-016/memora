import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _dockerfilePath = '.devcontainer/Dockerfile';
const _devcontainerJsonPath = '.devcontainer/devcontainer.json';
const _androidAppBuildGradlePath = 'android/app/build.gradle.kts';

void main() {
  group('DevContainer Dockerfile', () {
    test('Ubuntu 24.04をベースにFlutterとAndroid SDKをDockerfile内で導入する', () {
      final dockerfile = File(_dockerfilePath).readAsStringSync();

      expect(dockerfile, contains('FROM ubuntu:24.04'));
      expect(dockerfile, isNot(contains('instrumentisto/flutter')));
      expect(dockerfile, contains('ARG FLUTTER_VERSION=3.44.4'));
      expect(dockerfile, contains('ARG ANDROID_SDK_TOOLS_VERSION=14742923'));
      expect(dockerfile, contains('ARG ANDROID_PLATFORM_VERSION=36'));
      expect(dockerfile, contains('ARG ANDROID_BUILD_TOOLS_VERSION=36.0.0'));
      expect(dockerfile, contains('ARG ANDROID_NDK_VERSION=28.2.13676358'));
      expect(dockerfile, contains('ENV ANDROID_HOME=/opt/android-sdk-linux'));
      expect(
        dockerfile,
        contains(r'flutter_linux_${FLUTTER_VERSION}-stable.tar.xz'),
      );
      expect(
        dockerfile,
        contains(
          r'sdkmanager \'
          '\n'
          r'  "platforms;android-$ANDROID_PLATFORM_VERSION"',
        ),
      );
    });

    test('Dockerfile内で導入したAndroid SDKをvolumeで隠さない', () {
      final devcontainerJson = File(_devcontainerJsonPath).readAsStringSync();

      expect(devcontainerJson, isNot(contains('android-sdk-memora')));
      expect(
        devcontainerJson,
        isNot(contains('/opt/android-sdk-linux,type=volume')),
      );
    });

    test('Dockerfileで導入するNDKとAndroidアプリが要求するNDKを揃える', () {
      final dockerfile = File(_dockerfilePath).readAsStringSync();
      final androidAppBuildGradle =
          File(_androidAppBuildGradlePath).readAsStringSync();

      expect(dockerfile, contains('ARG ANDROID_NDK_VERSION=28.2.13676358'));
      expect(androidAppBuildGradle, contains('ndkVersion = "28.2.13676358"'));
    });
  });
}
