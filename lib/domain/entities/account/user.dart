import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.loginId,
    this.displayName,
    required this.isVerified,
  });

  final String id;
  final String loginId;
  final String? displayName;
  final bool isVerified;

  User copyWith({
    String? id,
    String? loginId,
    String? displayName,
    bool? isVerified,
  }) {
    return User(
      id: id ?? this.id,
      loginId: loginId ?? this.loginId,
      displayName: displayName ?? this.displayName,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  List<Object?> get props => [id, loginId, displayName, isVerified];
}
