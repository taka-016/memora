import 'package:equatable/equatable.dart';

enum AndroidWidgetActionResultStatus { success, failure }

class AndroidWidgetActionResultDto extends Equatable {
  const AndroidWidgetActionResultDto({
    required this.status,
    required this.message,
  });

  final AndroidWidgetActionResultStatus status;
  final String message;

  Map<String, dynamic> toJson() {
    return {'status': status.name, 'message': message};
  }

  @override
  List<Object?> get props => [status, message];
}
