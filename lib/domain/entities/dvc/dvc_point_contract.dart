import 'package:equatable/equatable.dart';

class DvcPointContract extends Equatable {
  const DvcPointContract({
    this.version,
    required this.id,
    required this.groupId,
    required this.contractName,
    required this.contractStartYearMonth,
    required this.contractEndYearMonth,
    required this.useYearStartMonth,
    required this.annualPoint,
  });

  final int? version;
  final String id;
  final String groupId;
  final String contractName;
  final DateTime contractStartYearMonth;
  final DateTime contractEndYearMonth;
  final int useYearStartMonth;
  final int annualPoint;

  DvcPointContract copyWith({
    int? version,
    String? id,
    String? groupId,
    String? contractName,
    DateTime? contractStartYearMonth,
    DateTime? contractEndYearMonth,
    int? useYearStartMonth,
    int? annualPoint,
  }) {
    return DvcPointContract(
      version: version ?? this.version,
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      contractName: contractName ?? this.contractName,
      contractStartYearMonth:
          contractStartYearMonth ?? this.contractStartYearMonth,
      contractEndYearMonth: contractEndYearMonth ?? this.contractEndYearMonth,
      useYearStartMonth: useYearStartMonth ?? this.useYearStartMonth,
      annualPoint: annualPoint ?? this.annualPoint,
    );
  }

  @override
  List<Object?> get props => [
    version,
    id,
    groupId,
    contractName,
    contractStartYearMonth,
    contractEndYearMonth,
    useYearStartMonth,
    annualPoint,
  ];
}
