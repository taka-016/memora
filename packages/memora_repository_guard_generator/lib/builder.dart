import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:memora_repository_guard_generator/generator.dart';

Builder repositoryGuardBuilder(BuilderOptions options) =>
    RepositoryGuardBuilder();

class RepositoryGuardBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {
    r'$lib$': ['application/decorators/repository_guards.g.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final sources = <String, String>{};
    await for (final asset in buildStep.findAssets(
      Glob('lib/domain/repositories/**/*.dart'),
    )) {
      sources[asset.path] = await buildStep.readAsString(asset);
    }
    final output = generateRepositoryGuards(
      sources,
      packageName: buildStep.inputId.package,
    );
    await buildStep.writeAsString(
      AssetId(
        buildStep.inputId.package,
        'lib/application/decorators/repository_guards.g.dart',
      ),
      output,
    );
  }
}
