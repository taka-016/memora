import 'package:equatable/equatable.dart';

class UserDto extends Equatable {
  const UserDto({
    required this.id,
    required this.loginId,
    this.displayName,
    required this.isVerified,
  });

  final String id;
  final String loginId;
  final String? displayName;
  final bool isVerified;

  UserDto copyWith({
    String? id,
    String? loginId,
    String? displayName,
    bool? isVerified,
  }) {
    return UserDto(
      id: id ?? this.id,
      loginId: loginId ?? this.loginId,
      displayName: displayName ?? this.displayName,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  List<Object?> get props => [id, loginId, displayName, isVerified];
}
