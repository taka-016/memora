import 'package:flutter_riverpod/legacy.dart';
import 'package:memora/infrastructure/config/auth_type.dart';

final authTypeProvider = StateProvider<AuthType>((ref) => AuthType.firebase);
