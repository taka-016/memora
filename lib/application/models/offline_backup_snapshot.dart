import 'dart:convert';

import 'package:equatable/equatable.dart';

class OfflineBackupAuthenticationException implements Exception {
  const OfflineBackupAuthenticationException();

  @override
  String toString() => 'バックアップのパスワードが誤っているか、ファイルが破損しています。';
}

class OfflineBackupUnsupportedVersionException implements Exception {
  const OfflineBackupUnsupportedVersionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OfflineBackupCurrentMember extends Equatable {
  const OfflineBackupCurrentMember({
    required this.id,
    required this.accountId,
    required this.displayName,
  });

  factory OfflineBackupCurrentMember.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final accountId = json['accountId'];
    final displayName = json['displayName'];
    if (id is! String ||
        id.isEmpty ||
        accountId is! String ||
        accountId.isEmpty ||
        displayName is! String ||
        displayName.isEmpty) {
      throw const FormatException('バックアップの本人情報が不正です。');
    }
    return OfflineBackupCurrentMember(
      id: id,
      accountId: accountId,
      displayName: displayName,
    );
  }

  final String id;
  final String accountId;
  final String displayName;

  Map<String, Object> toJson() => {
    'id': id,
    'accountId': accountId,
    'displayName': displayName,
  };

  @override
  List<Object?> get props => [id, accountId, displayName];
}

class OfflineBackupSettings extends Equatable {
  const OfflineBackupSettings({
    required this.androidWidgetUpdateIntervalMinutes,
    required this.showAge,
    required this.showGrade,
    required this.showYakudoshi,
  });

  factory OfflineBackupSettings.fromJson(Map<String, dynamic> json) {
    final interval = json['androidWidgetUpdateIntervalMinutes'];
    final showAge = json['showAge'];
    final showGrade = json['showGrade'];
    final showYakudoshi = json['showYakudoshi'];
    if (interval is! int ||
        interval <= 0 ||
        showAge is! bool ||
        showGrade is! bool ||
        showYakudoshi is! bool) {
      throw const FormatException('バックアップの設定情報が不正です。');
    }
    return OfflineBackupSettings(
      androidWidgetUpdateIntervalMinutes: interval,
      showAge: showAge,
      showGrade: showGrade,
      showYakudoshi: showYakudoshi,
    );
  }

  final int androidWidgetUpdateIntervalMinutes;
  final bool showAge;
  final bool showGrade;
  final bool showYakudoshi;

  Map<String, Object> toJson() => {
    'androidWidgetUpdateIntervalMinutes': androidWidgetUpdateIntervalMinutes,
    'showAge': showAge,
    'showGrade': showGrade,
    'showYakudoshi': showYakudoshi,
  };

  @override
  List<Object?> get props => [
    androidWidgetUpdateIntervalMinutes,
    showAge,
    showGrade,
    showYakudoshi,
  ];
}

class OfflineBackupSnapshot extends Equatable {
  const OfflineBackupSnapshot({
    required this.formatVersion,
    required this.databaseSchemaVersion,
    required this.currentMember,
    required this.settings,
    required this.tables,
  });

  factory OfflineBackupSnapshot.fromJson(Map<String, dynamic> json) {
    final formatVersion = json['formatVersion'];
    if (formatVersion != currentFormatVersion) {
      throw OfflineBackupUnsupportedVersionException(
        '未対応のバックアップ形式です: $formatVersion',
      );
    }
    final databaseSchemaVersion = json['databaseSchemaVersion'];
    final currentMember = json['currentMember'];
    final settings = json['settings'];
    final tables = json['tables'];
    if (databaseSchemaVersion is! int ||
        currentMember is! Map<String, dynamic> ||
        settings is! Map<String, dynamic> ||
        tables is! Map<String, dynamic>) {
      throw const FormatException('バックアップの論理データが不正です。');
    }
    return OfflineBackupSnapshot(
      formatVersion: formatVersion as int,
      databaseSchemaVersion: databaseSchemaVersion,
      currentMember: OfflineBackupCurrentMember.fromJson(currentMember),
      settings: OfflineBackupSettings.fromJson(settings),
      tables: tables.map((table, value) {
        if (value is! List) {
          throw const FormatException('バックアップのテーブル情報が不正です。');
        }
        return MapEntry(
          table,
          value
              .map((row) {
                if (row is! Map<String, dynamic>) {
                  throw const FormatException('バックアップの行データが不正です。');
                }
                return Map<String, Object?>.from(row);
              })
              .toList(growable: false),
        );
      }),
    );
  }

  static const currentFormatVersion = 1;
  static const tableNames = <String>{
    'members',
    'groups',
    'group_members',
    'trip_entries',
    'tasks',
    'itinerary_items',
    'member_events',
    'group_events',
    'dvc_point_contracts',
    'dvc_limited_points',
    'dvc_point_usages',
  };

  final int formatVersion;
  final int databaseSchemaVersion;
  final OfflineBackupCurrentMember currentMember;
  final OfflineBackupSettings settings;
  final Map<String, List<Map<String, Object?>>> tables;

  Map<String, Object> toJson() => {
    'formatVersion': formatVersion,
    'databaseSchemaVersion': databaseSchemaVersion,
    'currentMember': currentMember.toJson(),
    'settings': settings.toJson(),
    'tables': tables,
  };

  OfflineBackupSnapshot copyWith({
    int? databaseSchemaVersion,
    OfflineBackupCurrentMember? currentMember,
  }) => OfflineBackupSnapshot(
    formatVersion: formatVersion,
    databaseSchemaVersion: databaseSchemaVersion ?? this.databaseSchemaVersion,
    currentMember: currentMember ?? this.currentMember,
    settings: settings,
    tables: tables,
  );

  @override
  List<Object?> get props => [jsonEncode(toJson())];
}
