import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/models/app_capabilities.dart';
import 'package:memora/application/exceptions/feature_unavailable_exception.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/repositories/dvc/dvc_limited_point_repository.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_contract_repository.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_usage_repository.dart';
import 'package:memora/domain/repositories/group/group_event_repository.dart';
import 'package:memora/domain/repositories/group/group_repository.dart';
import 'package:memora/domain/repositories/member/member_event_repository.dart';
import 'package:memora/domain/repositories/member/member_invitation_repository.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/repositories/dvc/firestore_dvc_limited_point_repository.dart';
import 'package:memora/infrastructure/repositories/dvc/firestore_dvc_point_contract_repository.dart';
import 'package:memora/infrastructure/repositories/dvc/firestore_dvc_point_usage_repository.dart';
import 'package:memora/infrastructure/repositories/group/firestore_group_event_repository.dart';
import 'package:memora/infrastructure/repositories/group/firestore_group_repository.dart';
import 'package:memora/infrastructure/repositories/member/firestore_member_event_repository.dart';
import 'package:memora/infrastructure/repositories/member/firestore_member_invitation_repository.dart';
import 'package:memora/infrastructure/repositories/member/firestore_member_repository.dart';
import 'package:memora/infrastructure/repositories/trip/firestore_trip_entry_repository.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return RepositoryFactory.create<GroupRepository>(ref: ref);
});

final groupEventRepositoryProvider = Provider<GroupEventRepository>((ref) {
  return RepositoryFactory.create<GroupEventRepository>(ref: ref);
});

final memberEventRepositoryProvider = Provider<MemberEventRepository>((ref) {
  return RepositoryFactory.create<MemberEventRepository>(ref: ref);
});

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return RepositoryFactory.create<MemberRepository>(ref: ref);
});

final memberInvitationRepositoryProvider = Provider<MemberInvitationRepository>(
  (ref) {
    return RepositoryFactory.create<MemberInvitationRepository>(ref: ref);
  },
);

final tripEntryRepositoryProvider = Provider<TripEntryRepository>((ref) {
  return RepositoryFactory.create<TripEntryRepository>(ref: ref);
});

final dvcPointContractRepositoryProvider = Provider<DvcPointContractRepository>(
  (ref) {
    return RepositoryFactory.create<DvcPointContractRepository>(ref: ref);
  },
);

final dvcLimitedPointRepositoryProvider = Provider<DvcLimitedPointRepository>((
  ref,
) {
  return RepositoryFactory.create<DvcLimitedPointRepository>(ref: ref);
});

final dvcPointUsageRepositoryProvider = Provider<DvcPointUsageRepository>((
  ref,
) {
  return RepositoryFactory.create<DvcPointUsageRepository>(ref: ref);
});

class RepositoryFactory {
  static T create<T extends Object>({required Ref ref}) {
    final mode = ref.watch(appModeProvider);
    return _createRepositoryByMode<T>(mode);
  }

  static T _createRepositoryByMode<T extends Object>(AppMode mode) {
    switch (mode) {
      case AppMode.online:
        return _createFirestoreRepository<T>();
      case AppMode.offline:
        throw const FeatureUnavailableException(
          AppFeature.localData,
          '端末内データの保存機能は現在準備中です。',
        );
    }
  }

  static T _createFirestoreRepository<T>() {
    if (T == MemberRepository) {
      return FirestoreMemberRepository() as T;
    }
    if (T == GroupRepository) {
      return FirestoreGroupRepository() as T;
    }
    if (T == MemberEventRepository) {
      return FirestoreMemberEventRepository() as T;
    }
    if (T == MemberInvitationRepository) {
      return FirestoreMemberInvitationRepository() as T;
    }
    if (T == GroupEventRepository) {
      return FirestoreGroupEventRepository() as T;
    }
    if (T == TripEntryRepository) {
      return FirestoreTripEntryRepository() as T;
    }
    if (T == DvcPointContractRepository) {
      return FirestoreDvcPointContractRepository() as T;
    }
    if (T == DvcLimitedPointRepository) {
      return FirestoreDvcLimitedPointRepository() as T;
    }
    if (T == DvcPointUsageRepository) {
      return FirestoreDvcPointUsageRepository() as T;
    }
    throw ArgumentError('Unknown repository type: $T');
  }
}
