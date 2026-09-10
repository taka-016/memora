import 'dart:convert';
import 'dart:io';

import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/services/current_member_resolver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class LocalCurrentMemberResolver implements CurrentMemberResolver {
  LocalCurrentMemberResolver({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;
  Future<MemberDto>? _pending;

  @override
  Future<MemberDto> resolve() async {
    final pending = _pending ??= _loadOrCreate();
    try {
      return await pending;
    } finally {
      if (identical(_pending, pending)) _pending = null;
    }
  }

  Future<MemberDto> _loadOrCreate() async {
    final directory = await _directory();
    await directory.create(recursive: true);
    final file = File('${directory.path}/offline_current_member.json');
    if (await file.exists()) {
      final value = jsonDecode(await file.readAsString());
      if (value is! Map<String, dynamic> ||
          value['version'] != 1 ||
          value['id'] is! String ||
          (value['id'] as String).isEmpty ||
          value['accountId'] is! String ||
          (value['accountId'] as String).isEmpty ||
          value['displayName'] is! String ||
          (value['displayName'] as String).isEmpty) {
        throw const FormatException('端末内の本人情報を読み込めませんでした。');
      }
      return MemberDto(
        id: value['id'] as String,
        accountId: value['accountId'] as String,
        displayName: value['displayName'] as String,
      );
    }
    final member = MemberDto(
      id: const Uuid().v4(),
      accountId: const Uuid().v4(),
      displayName: '本人',
    );
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode({
        'version': 1,
        'id': member.id,
        'accountId': member.accountId,
        'displayName': member.displayName,
      }),
      flush: true,
    );
    await temporary.rename(file.path);
    return member;
  }
}
