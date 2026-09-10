import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/infrastructure/database/sqlite_values.dart';

class SqliteDvcPointContractMapper {
  static DvcPointContractDto fromRow(Map<String, Object?> row) => DvcPointContractDto(
id: row['id'] as String,
groupId: row['group_id'] as String,
contractName: row['contract_name'] as String,
contractStartYearMonth: SqliteValues.date(row['contract_start_year_month'])!,
contractEndYearMonth: SqliteValues.date(row['contract_end_year_month'])!,
useYearStartMonth: row['use_year_start_month'] as int,
annualPoint: row['annual_point'] as int
);
  static Map<String, Object?> toRow(DvcPointContract value) => {
'id': value.id,
'group_id': value.groupId,
'contract_name': value.contractName,
'contract_start_year_month': value.contractStartYearMonth.microsecondsSinceEpoch,
'contract_end_year_month': value.contractEndYearMonth.microsecondsSinceEpoch,
'use_year_start_month': value.useYearStartMonth,
'annual_point': value.annualPoint,
};
}
