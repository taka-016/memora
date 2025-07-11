import 'package:equatable/equatable.dart';

class Group extends Equatable {
  const Group({
    required this.id,
    required this.administratorId,
    required this.name,
    this.memo,
  });

  final String id;
  final String administratorId;
  final String name;
  final String? memo;

  Group copyWith({
    String? id,
    String? administratorId,
    String? name,
    String? memo,
  }) {
    return Group(
      id: id ?? this.id,
      administratorId: administratorId ?? this.administratorId,
      name: name ?? this.name,
      memo: memo ?? this.memo,
    );
  }

  @override
  List<Object?> get props => [id, administratorId, name, memo];
}
