import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'presentation/top_page.dart';
import 'presentation/auth/auth_guard.dart';
import 'application/managers/auth_manager.dart';
import 'infrastructure/services/firebase_auth_service.dart';
import 'domain/services/auth_service.dart';
import 'application/usecases/get_groups_with_members_usecase.dart';
import 'application/usecases/get_or_create_member_usecase.dart';
import 'application/usecases/get_current_member_usecase.dart';
import 'infrastructure/repositories/firestore_group_repository.dart';
import 'infrastructure/repositories/firestore_group_member_repository.dart';
import 'infrastructure/repositories/firestore_member_repository.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firestoreのローカルキャッシュを無効化
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // 依存性注入を一度だけ初期化
  late final AuthService authService;
  late final FirestoreMemberRepository memberRepository;
  late final GetOrCreateMemberUseCase getOrCreateMemberUseCase;
  late final AuthManager authManager;
  late final FirestoreGroupRepository groupRepository;
  late final FirestoreGroupMemberRepository groupMemberRepository;
  late final GetGroupsWithMembersUsecase getGroupsWithMembersUsecase;
  late final GetCurrentMemberUseCase getCurrentMemberUseCase;

  @override
  void initState() {
    super.initState();
    authService = FirebaseAuthService();
    memberRepository = FirestoreMemberRepository();
    getOrCreateMemberUseCase = GetOrCreateMemberUseCase(memberRepository);
    authManager = AuthManager(
      authService: authService,
      getOrCreateMemberUseCase: getOrCreateMemberUseCase,
    );

    groupRepository = FirestoreGroupRepository();
    groupMemberRepository = FirestoreGroupMemberRepository();
    getGroupsWithMembersUsecase = GetGroupsWithMembersUsecase(
      groupRepository: groupRepository,
      groupMemberRepository: groupMemberRepository,
      memberRepository: memberRepository,
    );

    getCurrentMemberUseCase = GetCurrentMemberUseCase(
      memberRepository,
      authService,
    );
  }

  @override
  Widget build(BuildContext context) {
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
