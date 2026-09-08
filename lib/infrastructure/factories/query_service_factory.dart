import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/models/app_capabilities.dart';
import 'package:memora/application/exceptions/feature_unavailable_exception.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/composition_root/providers/app_clock_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/queries/dvc/dvc_limited_point_query_service.dart';
import 'package:memora/application/queries/dvc/dvc_point_contract_query_service.dart';
import 'package:memora/application/queries/dvc/dvc_point_usage_query_service.dart';
import 'package:memora/application/queries/group/group_event_query_service.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/queries/member/member_event_query_service.dart';
import 'package:memora/application/queries/member/member_invitation_query_service.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/application/queries/trip/itinerary_item_query_service.dart';
import 'package:memora/application/queries/trip/location_query_service.dart';
import 'package:memora/application/queries/trip/task_query_service.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/infrastructure/queries/dvc/firestore_dvc_limited_point_query_service.dart';
import 'package:memora/infrastructure/queries/dvc/firestore_dvc_point_contract_query_service.dart';
import 'package:memora/infrastructure/queries/dvc/firestore_dvc_point_usage_query_service.dart';
import 'package:memora/infrastructure/queries/group/firestore_group_event_query_service.dart';
import 'package:memora/infrastructure/queries/group/firestore_group_query_service.dart';
import 'package:memora/infrastructure/queries/member/firestore_member_event_query_service.dart';
import 'package:memora/infrastructure/queries/member/firestore_member_invitation_query_service.dart';
import 'package:memora/infrastructure/queries/member/firestore_member_query_service.dart';
import 'package:memora/infrastructure/queries/trip/firestore_itinerary_item_query_service.dart';
import 'package:memora/infrastructure/queries/trip/firestore_location_query_service.dart';
import 'package:memora/infrastructure/queries/trip/firestore_task_query_service.dart';
import 'package:memora/infrastructure/queries/trip/firestore_trip_entry_query_service.dart';

final groupQueryServiceProvider = Provider<GroupQueryService>((ref) {
  return QueryServiceFactory.create<GroupQueryService>(ref: ref);
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final groupEventQueryServiceProvider = Provider<GroupEventQueryService>((ref) {
  return QueryServiceFactory.create<GroupEventQueryService>(ref: ref);
});

final tripEntryQueryServiceProvider = Provider<TripEntryQueryService>((ref) {
  return QueryServiceFactory.create<TripEntryQueryService>(ref: ref);
});

final mapTripEntryQueryServiceProvider = Provider<TripEntryQueryService>((ref) {
  return QueryServiceFactory.createTripEntryQueryService(
    ref: ref,
    rethrowOnError: true,
  );
});

final taskQueryServiceProvider = Provider<TaskQueryService>((ref) {
  return QueryServiceFactory.create<TaskQueryService>(ref: ref);
});

final itineraryItemQueryServiceProvider = Provider<ItineraryItemQueryService>((
  ref,
) {
  return QueryServiceFactory.create<ItineraryItemQueryService>(ref: ref);
});

final locationQueryServiceProvider = Provider<LocationQueryService>((ref) {
  return QueryServiceFactory.create<LocationQueryService>(ref: ref);
});

final memberQueryServiceProvider = Provider<MemberQueryService>((ref) {
  return QueryServiceFactory.create<MemberQueryService>(ref: ref);
});

final memberEventQueryServiceProvider = Provider<MemberEventQueryService>((
  ref,
) {
  return QueryServiceFactory.create<MemberEventQueryService>(ref: ref);
});

final memberInvitationQueryServiceProvider =
    Provider<MemberInvitationQueryService>((ref) {
      return QueryServiceFactory.create<MemberInvitationQueryService>(ref: ref);
    });

final dvcPointContractQueryServiceProvider =
    Provider<DvcPointContractQueryService>((ref) {
      return QueryServiceFactory.create<DvcPointContractQueryService>(ref: ref);
    });

final dvcLimitedPointQueryServiceProvider =
    Provider<DvcLimitedPointQueryService>((ref) {
      return QueryServiceFactory.create<DvcLimitedPointQueryService>(ref: ref);
    });

final dvcPointUsageQueryServiceProvider = Provider<DvcPointUsageQueryService>((
  ref,
) {
  return QueryServiceFactory.create<DvcPointUsageQueryService>(ref: ref);
});

class QueryServiceFactory {
  static T create<T extends Object>({
    required Ref ref,
    bool rethrowOnError = false,
  }) {
    final dbType = ref.watch(appModeProvider);
    return _createQueryServiceByType<T>(
      dbType,
      ref: ref,
      rethrowOnError: rethrowOnError,
    );
  }

  static T _createQueryServiceByType<T extends Object>(
    AppMode dbType, {
    required Ref ref,
    required bool rethrowOnError,
  }) {
    switch (dbType) {
      case AppMode.online:
        return _createFirestoreQueryService<T>(
          ref: ref,
          rethrowOnError: rethrowOnError,
        );
      case AppMode.offline:
        throw const FeatureUnavailableException(
          AppFeature.localData,
          '端末内データの保存機能は現在準備中です。',
        );
    }
  }

  static TripEntryQueryService createTripEntryQueryService({
    required Ref ref,
    bool rethrowOnError = false,
  }) {
    final dbType = ref.watch(appModeProvider);
    switch (dbType) {
      case AppMode.online:
        return FirestoreTripEntryQueryService(
          firestore: ref.watch(firebaseFirestoreProvider),
          clock: ref.watch(appClockProvider),
          rethrowOnError: rethrowOnError,
        );
      case AppMode.offline:
        throw const FeatureUnavailableException(
          AppFeature.localData,
          '端末内データの保存機能は現在準備中です。',
        );
    }
  }

  static T _createFirestoreQueryService<T>({
    required Ref ref,
    required bool rethrowOnError,
  }) {
    if (T == GroupQueryService) {
      return FirestoreGroupQueryService() as T;
    }
    if (T == GroupEventQueryService) {
      return FirestoreGroupEventQueryService() as T;
    }
    if (T == TripEntryQueryService) {
      return createTripEntryQueryService(
        ref: ref,
        rethrowOnError: rethrowOnError,
      ) as T;
    }
    if (T == TaskQueryService) {
      return FirestoreTaskQueryService() as T;
    }
    if (T == ItineraryItemQueryService) {
      return FirestoreItineraryItemQueryService(
        rethrowOnError: rethrowOnError,
        firestore: ref.watch(firebaseFirestoreProvider),
      ) as T;
    }
    if (T == LocationQueryService) {
      return FirestoreLocationQueryService(
        firestore: ref.watch(firebaseFirestoreProvider),
      ) as T;
    }
    if (T == MemberQueryService) {
      return FirestoreMemberQueryService() as T;
    }
    if (T == MemberEventQueryService) {
      return FirestoreMemberEventQueryService() as T;
    }
    if (T == MemberInvitationQueryService) {
      return FirestoreMemberInvitationQueryService() as T;
    }
    if (T == DvcPointContractQueryService) {
      return FirestoreDvcPointContractQueryService() as T;
    }
    if (T == DvcLimitedPointQueryService) {
      return FirestoreDvcLimitedPointQueryService() as T;
    }
    if (T == DvcPointUsageQueryService) {
      return FirestoreDvcPointUsageQueryService() as T;
    }
    throw ArgumentError('Unknown query service type: $T');
  }
}

final androidWidgetItineraryItemQueryServiceProvider =
    Provider<ItineraryItemQueryService>((ref) {
      return QueryServiceFactory.create<ItineraryItemQueryService>(
        ref: ref,
        rethrowOnError: true,
      );
    });
