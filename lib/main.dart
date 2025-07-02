import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'presentation/top_page.dart';
import 'presentation/auth/auth_guard.dart';
import 'application/managers/auth_manager.dart';
import 'infrastructure/services/firebase_auth_service.dart';
import 'infrastructure/services/production_firebase_initializer.dart';
import 'domain/services/auth_service.dart';
import 'domain/services/firebase_initializer.dart';
import 'application/usecases/get_groups_with_members_usecase.dart';
import 'application/usecases/get_or_create_member_usecase.dart';
import 'application/usecases/get_current_member_usecase.dart';
import 'infrastructure/repositories/firestore_group_repository.dart';
import 'infrastructure/repositories/firestore_group_member_repository.dart';
import 'infrastructure/repositories/firestore_member_repository.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  await runAppWithDI(ProductionFirebaseInitializer());
}

Future<void> runAppWithDI(FirebaseInitializer firebaseInitializer) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase初期化
  try {
    await firebaseInitializer.initialize();
  } catch (e) {
    // Firebase初期化エラーをキャッチ
    // print('Firebase initialization failed: $e');
  }

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 依存性注入
    final authService = FirebaseAuthService();
    final memberRepository = FirestoreMemberRepository();
    final getOrCreateMemberUseCase = GetOrCreateMemberUseCase(memberRepository);
    final authManager = AuthManager(
      authService: authService,
      getOrCreateMemberUseCase: getOrCreateMemberUseCase,
    );

    final groupRepository = FirestoreGroupRepository();
    final groupMemberRepository = FirestoreGroupMemberRepository();
    final getGroupsWithMembersUsecase = GetGroupsWithMembersUsecase(
      groupRepository: groupRepository,
      groupMemberRepository: groupMemberRepository,
      memberRepository: memberRepository,
    );

    final getCurrentMemberUseCase = GetCurrentMemberUseCase(
      memberRepository,
      authService,
    );

    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider.value(value: authManager),
      ],
      child: MaterialApp(
        title: 'memora',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        locale: const Locale('ja'),
        supportedLocales: const [Locale('ja'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Consumer<AuthManager>(
          builder: (context, authManager, child) {
            return AuthGuard(
              authManager: authManager,
              child: TopPage(
                getGroupsWithMembersUsecase: getGroupsWithMembersUsecase,
                getCurrentMemberUseCase: getCurrentMemberUseCase,
              ),
            );
          },
        ),
      ),
    );
  }
}
