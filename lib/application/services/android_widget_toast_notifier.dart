import 'package:equatable/equatable.dart';

enum AndroidWidgetToastNotificationType {
  success('success'),
  error('error');

  const AndroidWidgetToastNotificationType(this.value);

  final String value;
}

class AndroidWidgetToastNotification extends Equatable {
  const AndroidWidgetToastNotification({
    required this.type,
    required this.message,
  });

  const AndroidWidgetToastNotification.success(String message)
    : this(type: AndroidWidgetToastNotificationType.success, message: message);

  const AndroidWidgetToastNotification.error(String message)
    : this(type: AndroidWidgetToastNotificationType.error, message: message);

  final AndroidWidgetToastNotificationType type;
  final String message;

  Map<String, String> toMethodChannelArguments() {
    return {'type': type.value, 'message': message};
  }

  @override
  List<Object?> get props => [type, message];
}

abstract interface class AndroidWidgetToastNotifier {
  Future<void> show(AndroidWidgetToastNotification notification);
}
