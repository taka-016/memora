import 'package:flutter_test/flutter_test.dart';
import 'package:memora_repository_guard_generator/generator.dart';

void main() {
  test('Repositoryと更新メソッドの追加を個別登録せずガードへ反映する', () {
    final sources = {
      'lib/domain/repositories/first_repository.dart': '''
abstract class FirstRepository {
  Future<String> save(String value);
}
''',
    };
    final before = generateRepositoryGuards(sources, packageName: 'example');
    expect(before, contains('T == FirstRepository'));
    sources['lib/domain/repositories/new_repository.dart'] = '''
abstract class NewRepository {
  Future<void> delete(String id, {int? expectedVersion});
}
''';
    final after = generateRepositoryGuards(sources, packageName: 'example');
    expect(after, contains('T == FirstRepository'));
    expect(after, contains('T == NewRepository'));
    expect(after, contains('class GuardedNewRepository implements NewRepository'));
    expect(after, contains('await _ensureAvailable();'));
    expect(after, contains('expectedVersion: expectedVersion'));
    sources['lib/domain/repositories/new_repository.dart'] = '''
abstract class NewRepository {
  Future<void> delete(String id, {int? expectedVersion});
  Future<String> create(String value);
}
''';
    final updated = generateRepositoryGuards(sources, packageName: 'example');
    expect(updated, contains('return await _delegate.create(value);'));
  });

  test('型と省略可能引数の既定値を保持して更新処理へ渡す', () {
    final result = generateRepositoryGuards({
      'lib/domain/repositories/event_repository.dart': '''
import 'package:example/domain/entities/event.dart';
abstract class EventRepository {
  Future<Event?> save(
    Event value, {
    required String groupId,
    Map<String, int> versions = const {},
    List<Event> preserved = const [],
  });
}
''',
    }, packageName: 'example');
    expect(result, contains("import 'package:example/domain/entities/event.dart';"));
    expect(result, contains('Future<Event?> save('));
    expect(result, contains('required String groupId'));
    expect(result, contains('Map<String, int> versions = const {}'));
    expect(result, contains('List<Event> preserved = const []'));
    expect(result, contains('groupId: groupId'));
    expect(result, contains('versions: versions'));
    expect(result, contains('preserved: preserved'));
  });
}
