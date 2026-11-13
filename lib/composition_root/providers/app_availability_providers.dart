import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/usecases/app_availability/check_app_availability_usecase.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/services/firestore_app_availability_source.dart';

final checkAppAvailabilityUsecaseProvider =
    Provider<CheckAppAvailabilityUsecase>((ref) {
      if (ref.watch(appModeProvider) == AppMode.offline) {
        return const CheckAppAvailabilityUsecase.unrestricted();
      }
      return CheckAppAvailabilityUsecase(
        source: FirestoreAppAvailabilitySource(
          firestore: FirebaseFirestore.instance,
        ),
        loadBuildNumber: () async =>
            int.parse((await PackageInfo.fromPlatform()).buildNumber),
      );
    });
