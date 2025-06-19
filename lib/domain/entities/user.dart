import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    this.displayName,
    required this.isEmailVerified,
  });

  final String id;
  final String email;
  final String? displayName;
  final bool isEmailVerified;

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    bool? isEmailVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  @override
  List<Object?> get props => [id, email, displayName, isEmailVerified];
}