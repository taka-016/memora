import 'package:equatable/equatable.dart';

class OrderBy extends Equatable {
  const OrderBy(this.field, {this.descending = false});

  final String field;
  final bool descending;

  @override
  List<Object> get props => [field, descending];

  @override
  String toString() => 'OrderBy(field: $field, descending: $descending)';
}
