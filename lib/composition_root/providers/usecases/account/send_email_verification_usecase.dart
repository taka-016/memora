import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/application/usecases/account/send_email_verification_usecase.dart';

final sendEmailVerificationUseCaseProvider =
    Provider<SendEmailVerificationUseCase>((ref) {
      return SendEmailVerificationUseCase(
        authService: ref.watch(authServiceProvider),
      );
    });
