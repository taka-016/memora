import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/config/auth_type.dart';

final authTypeProvider = StateProvider<AuthType>((ref) => AuthType.firebase);
