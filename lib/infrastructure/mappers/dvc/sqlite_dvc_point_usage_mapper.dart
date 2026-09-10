import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/infrastructure/database/sqlite_values.dart';

class SqliteDvcPointUsageMapper {
  static DvcPointUsageDto fromRow(Map<String, Object?> row) => DvcPointUsageDto(
id: row['id'] as String,
groupId: row['group_id'] as String,
usageYearMonth: SqliteValues.date(row['usage_year_month'])!,
usedPoint: row['used_point'] as int,
memo: row['memo'] as String?
);
  static Map<String, Object?> toRow(DvcPointUsage value) => {
'id': value.id,
'group_id': value.groupId,
'usage_year_month': value.usageYearMonth.microsecondsSinceEpoch,
'used_point': value.usedPoint,
'memo': value.memo,
};
}
