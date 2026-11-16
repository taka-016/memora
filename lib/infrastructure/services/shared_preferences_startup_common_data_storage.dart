import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:memora/application/models/startup_common_data.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/services/startup_common_data_storage.dart';

class SharedPreferencesStartupCommonDataStorage
    implements StartupCommonDataStorage {
  const SharedPreferencesStartupCommonDataStorage();
  String _key(String owner) => 'startup_common_${Uri.encodeComponent(owner)}';
  @override
  Future<StartupCommonData?> load(String owner) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    final raw = preferences.getString(_key(owner));
    if (raw == null) return null;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return StartupCommonData(
      groups: (data['groups'] as List?)
          ?.map((g) => _readGroup(g as Map<String, dynamic>))
          .toList(),
      labels: (data['labels'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as List)
              .map((l) => _readLabel(l as Map<String, dynamic>))
              .toList(),
        ),
      ),
    );
  }

  @override
  Future<void> save(String owner, StartupCommonData data) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _key(owner),
      jsonEncode({
        'groups': data.groups?.map(_writeGroup).toList(),
        'labels': data.labels.map(
          (key, value) => MapEntry(key, value.map(_writeLabel).toList()),
        ),
      }),
    );
    if (!saved) throw StateError('共通データのキャッシュを保存できませんでした');
  }

  Map<String, dynamic> _writeGroup(GroupDto value) => {
    'version': value.version,
    'id': value.id,
    'ownerId': value.ownerId,
    'name': value.name,
    'memo': value.memo,
    'color': value.color,
    'textColor': value.textColor,
    'members': value.members.map(_writeMember).toList(),
    'originalMembers': value.originalMembers?.map(_writeMember).toList(),
  };
  GroupDto _readGroup(Map<String, dynamic> value) => GroupDto(
    version: value['version'] as int?,
    id: value['id'] as String,
    ownerId: value['ownerId'] as String,
    name: value['name'] as String,
    memo: value['memo'] as String?,
    color: value['color'] as String,
    textColor: value['textColor'] as String?,
    members: (value['members'] as List)
        .map((m) => _readMember(m as Map<String, dynamic>))
        .toList(),
    originalMembers: (value['originalMembers'] as List?)
        ?.map((m) => _readMember(m as Map<String, dynamic>))
        .toList(),
  );
  Map<String, dynamic> _writeMember(GroupMemberDto value) => {
    'memberId': value.memberId,
    'groupId': value.groupId,
    'orderIndex': value.orderIndex,
    'color': value.color,
    'textColor': value.textColor,
    'accountId': value.accountId,
    'ownerId': value.ownerId,
    'hiraganaFirstName': value.hiraganaFirstName,
    'hiraganaLastName': value.hiraganaLastName,
    'kanjiFirstName': value.kanjiFirstName,
    'kanjiLastName': value.kanjiLastName,
    'firstName': value.firstName,
    'lastName': value.lastName,
    'displayName': value.displayName,
    'type': value.type,
    'gender': value.gender,
    'email': value.email,
    'phoneNumber': value.phoneNumber,
    'isAdministrator': value.isAdministrator,
    'birthday': value.birthday?.toIso8601String(),
  };
  GroupMemberDto _readMember(Map<String, dynamic> value) => GroupMemberDto(
    memberId: value['memberId'] as String,
    groupId: value['groupId'] as String,
    orderIndex: value['orderIndex'] as int,
    color: value['color'] as String,
    textColor: value['textColor'] as String?,
    accountId: value['accountId'] as String?,
    ownerId: value['ownerId'] as String?,
    hiraganaFirstName: value['hiraganaFirstName'] as String?,
    hiraganaLastName: value['hiraganaLastName'] as String?,
    kanjiFirstName: value['kanjiFirstName'] as String?,
    kanjiLastName: value['kanjiLastName'] as String?,
    firstName: value['firstName'] as String?,
    lastName: value['lastName'] as String?,
    displayName: value['displayName'] as String,
    type: value['type'] as String?,
    gender: value['gender'] as String?,
    email: value['email'] as String?,
    phoneNumber: value['phoneNumber'] as String?,
    isAdministrator: value['isAdministrator'] as bool,
    birthday: value['birthday'] == null
        ? null
        : DateTime.parse(value['birthday'] as String),
  );
  Map<String, dynamic> _writeLabel(CalendarLabelDto value) => {
    'version': value.version,
    'labelType': value.labelType,
    'memberId': value.memberId,
    'isSelectable': value.isSelectable,
    'id': value.id,
    'groupId': value.groupId,
    'name': value.name,
    'color': value.color,
    'textColor': value.textColor,
    'sortOrder': value.sortOrder,
  };
  CalendarLabelDto _readLabel(Map<String, dynamic> value) => CalendarLabelDto(
    version: value['version'] as int?,
    labelType: value['labelType'] as String,
    memberId: value['memberId'] as String,
    isSelectable: value['isSelectable'] as bool,
    id: value['id'] as String,
    groupId: value['groupId'] as String,
    name: value['name'] as String,
    color: value['color'] as String,
    textColor: value['textColor'] as String,
    sortOrder: value['sortOrder'] as int,
  );
}
