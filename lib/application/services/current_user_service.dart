import 'package:memora/domain/entities/account/user.dart';

abstract class CurrentUserService {
  Future<User?> getCurrentUser();
}
