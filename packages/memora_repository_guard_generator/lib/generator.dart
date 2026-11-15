import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:dart_style/dart_style.dart';

String generateRepositoryGuards(
  Map<String, String> sources, {
  required String packageName,
}) {
  final imports = <String>{};
  final repositories = <ClassDeclaration>[];
  for (final path in sources.keys.toList()..sort()) {
    final uri = Uri.parse('package:$packageName/${path.substring(4)}');
    final unit = parseString(content: sources[path]!, path: path).unit;
    imports.add("import '$uri';");
    for (final directive in unit.directives.whereType<ImportDirective>()) {
      final imported = uri.resolve(directive.uri.stringValue!);
      imports.add(
        directive.toSource().replaceFirst(
          directive.uri.toSource(),
          "'$imported'",
        ),
      );
    }
    repositories.addAll(unit.declarations.whereType<ClassDeclaration>());
  }
  final result = StringBuffer()
    ..writeln('// 自動生成ファイルです。直接編集しないでください。')
    ..writeln('// ignore_for_file: type=lint')
    ..writeln()
    ..writeln((imports.toList()..sort()).join('\n'))
    ..writeln()
    ..writeln('T guardRepository<T extends Object>(')
    ..writeln('T repository, Future<void> Function() ensureAvailable,')
    ..writeln(') {');
  for (final repository in repositories) {
    final name = repository.namePart.typeName.lexeme;
    result
      ..writeln('if (T == $name) {')
      ..writeln(
        'return Guarded$name(repository as $name, ensureAvailable) as T;',
      )
      ..writeln('}');
  }
  result
    ..writeln("throw ArgumentError('未対応のRepositoryです: \$T');")
    ..writeln('}');
  for (final repository in repositories) {
    final name = repository.namePart.typeName.lexeme;
    result
      ..writeln('class Guarded$name implements $name {')
      ..writeln('const Guarded$name(this._delegate, this._ensureAvailable);')
      ..writeln('final $name _delegate;')
      ..writeln('final Future<void> Function() _ensureAvailable;');
    for (final method
        in repository.body.members.whereType<MethodDeclaration>()) {
      final arguments = method.parameters!.parameters
          .map((parameter) {
            final name = parameter.name!.lexeme;
            return parameter.isNamed ? '$name: $name' : name;
          })
          .join(', ');
      result
        ..writeln('@override')
        ..writeln(
          '${method.returnType!.toSource()} ${method.name.lexeme}${method.parameters!.toSource()} async {',
        )
        ..writeln('await _ensureAvailable();')
        ..writeln('return await _delegate.${method.name.lexeme}($arguments);')
        ..writeln('}');
    }
    result.writeln('}');
  }
  return DartFormatter(languageVersion: DartFormatter.latestLanguageVersion)
      .format(result.toString());
}
