import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/value-objects/auth_state.dart';
import '../../domain/services/auth_service.dart';
import '../../domain/repositories/member_repository.dart';
import '../../infrastructure/services/firebase_auth_service.dart';
import '../../infrastructure/repositories/firestore_member_repository.dart';
import '../managers/auth_manager.dart';
import '../usecases/get_or_create_member_usecase.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService();
});

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return FirestoreMemberRepository();
});

final getOrCreateMemberUseCaseProvider = Provider<GetOrCreateMemberUseCase>((
  ref,
) {
  final memberRepository = ref.watch(memberRepositoryProvider);
  return GetOrCreateMemberUseCase(memberRepository);
});

final authManagerProvider = StateNotifierProvider<AuthManager, AuthState>((
  ref,
) {
  final authService = ref.watch(authServiceProvider);
  final getOrCreateMemberUseCase = ref.watch(getOrCreateMemberUseCaseProvider);

  final authManager = AuthManager(
    authService: authService,
    getOrCreateMemberUseCase: getOrCreateMemberUseCase,
  );

  // 初期化を実行
  authManager.initialize();

  return authManager;
});
