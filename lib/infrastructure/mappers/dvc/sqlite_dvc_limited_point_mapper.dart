import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/infrastructure/database/sqlite_values.dart';

class SqliteDvcLimitedPointMapper {
  static DvcLimitedPointDto fromRow(Map<String, Object?> row) =>
      DvcLimitedPointDto(
        id: row['id'] as String,
        groupId: row['group_id'] as String,
        startYearMonth: SqliteValues.date(row['start_year_month'])!,
        endYearMonth: SqliteValues.date(row['end_year_month'])!,
        point: row['point'] as int,
        memo: row['memo'] as String?,
      );
  static Map<String, Object?> toRow(DvcLimitedPoint value) => {
    'id': value.id,
    'group_id': value.groupId,
    'start_year_month': value.startYearMonth.microsecondsSinceEpoch,
    'end_year_month': value.endYearMonth.microsecondsSinceEpoch,
    'point': value.point,
    'memo': value.memo,
  };
}
