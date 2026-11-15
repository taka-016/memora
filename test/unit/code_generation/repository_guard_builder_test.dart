import 'package:build/build.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_repository_guard_generator/builder.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'repository_guard_builder_test.mocks.dart';

@GenerateMocks([BuildStep])
void main() {
  test('全Repositoryファイルを発見し注釈も個別設定もなくガードを生成する', () async {
    final step = MockBuildStep();
    final first = AssetId('example', 'lib/domain/repositories/first_repository.dart');
    final added = AssetId('example', 'lib/domain/repositories/new/new_repository.dart');
    when(step.inputId).thenReturn(AssetId('example', r'lib/$lib$'));
    when(step.findAssets(any)).thenAnswer((_) => Stream.fromIterable([first, added]));
    when(step.readAsString(first)).thenAnswer((_) async => '''
abstract class FirstRepository { Future<void> save(String value); }
''');
    when(step.readAsString(added)).thenAnswer((_) async => '''
abstract class NewRepository { Future<void> delete(String id); }
''');
    when(step.writeAsString(any, any)).thenAnswer((_) async {});
    final builder = repositoryGuardBuilder(BuilderOptions.empty);
    await builder.build(step);
    final output = verify(step.writeAsString(
      AssetId('example', 'lib/application/decorators/guarded_repositories.g.dart'),
      captureAny,
    )).captured.single as String;
    expect(output, contains('T == FirstRepository'));
    expect(output, contains('T == NewRepository'));
    expect(output, contains('await _ensureAvailable();'));
    verify(step.findAssets(argThat(predicate<dynamic>((glob) => glob.pattern == 'lib/domain/repositories/**/*.dart')))).called(1);
  });
}
