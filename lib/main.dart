import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/application/interfaces/group_query_service.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/infrastructure/services/firestore_group_query_service.dart';
import 'firebase_options.dart';
import 'presentation/app/top_page.dart';
import 'presentation/features/auth/auth_guard.dart';
import 'application/interfaces/auth_service.dart';
import 'infrastructure/services/firebase_auth_service.dart';
import 'application/usecases/group/get_groups_with_members_usecase.dart';
import 'application/usecases/member/get_current_member_usecase.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

late final Logger logger;

Future<void> main() async {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await initLogger();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );

      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

      runApp(const ProviderScope(child: MyApp()));
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final AuthService authService;
  late final MemberRepository memberRepository;
  late final GroupQueryService groupQueryService;
  late final GetGroupsWithMembersUsecase getGroupsWithMembersUsecase;
  late final GetCurrentMemberUseCase getCurrentMemberUseCase;

  @override
  void initState() {
    super.initState();
    authService = FirebaseAuthService();
    memberRepository = RepositoryFactory.createWithWidgetRef<MemberRepository>(
      ref: ref,
    );

    groupQueryService = FirestoreGroupQueryService();
    getGroupsWithMembersUsecase = GetGroupsWithMembersUsecase(
      groupQueryService,
    );

    getCurrentMemberUseCase = GetCurrentMemberUseCase(
      memberRepository,
      authService,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'memora',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.lightBlue,
            foregroundColor: Colors.white,
          ),
        ),
        locale: const Locale('ja'),
        supportedLocales: const [Locale('ja'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: AuthGuard(
          child: TopPage(
            getGroupsWithMembersUsecase: getGroupsWithMembersUsecase,
            getCurrentMemberUseCase: getCurrentMemberUseCase,
          ),
        ),
      ),
    );
  }
}
