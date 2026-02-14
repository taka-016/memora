import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/queries/dvc/dvc_limited_point_query_service.dart';
import 'package:memora/application/queries/dvc/dvc_point_contract_query_service.dart';
import 'package:memora/application/queries/dvc/dvc_point_usage_query_service.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/queries/member/member_invitation_query_service.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/application/queries/trip/pin_query_service.dart';
import 'package:memora/application/queries/trip/task_query_service.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/infrastructure/config/database_type.dart';
import 'package:memora/infrastructure/config/database_type_provider.dart';
import 'package:memora/infrastructure/queries/dvc/firestore_dvc_limited_point_query_service.dart';
import 'package:memora/infrastructure/queries/dvc/firestore_dvc_point_contract_query_service.dart';
import 'package:memora/infrastructure/queries/dvc/firestore_dvc_point_usage_query_service.dart';
import 'package:memora/infrastructure/queries/group/firestore_group_query_service.dart';
import 'package:memora/infrastructure/queries/member/firestore_member_invitation_query_service.dart';
import 'package:memora/infrastructure/queries/member/firestore_member_query_service.dart';
import 'package:memora/infrastructure/queries/trip/firestore_pin_query_service.dart';
import 'package:memora/infrastructure/queries/trip/firestore_task_query_service.dart';
import 'package:memora/infrastructure/queries/trip/firestore_trip_entry_query_service.dart';

final groupQueryServiceProvider = Provider<GroupQueryService>((ref) {
  return QueryServiceFactory.create<GroupQueryService>(ref: ref);
});

final pinQueryServiceProvider = Provider<PinQueryService>((ref) {
  return QueryServiceFactory.create<PinQueryService>(ref: ref);
});

final tripEntryQueryServiceProvider = Provider<TripEntryQueryService>((ref) {
  return QueryServiceFactory.create<TripEntryQueryService>(ref: ref);
});

final taskQueryServiceProvider = Provider<TaskQueryService>((ref) {
  return QueryServiceFactory.create<TaskQueryService>(ref: ref);
});

final memberQueryServiceProvider = Provider<MemberQueryService>((ref) {
  return QueryServiceFactory.create<MemberQueryService>(ref: ref);
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
  static T create<T extends Object>({required Ref ref}) {
    final dbType = ref.watch(databaseTypeProvider);
    return _createQueryServiceByType<T>(dbType);
  }

  static T _createQueryServiceByType<T extends Object>(DatabaseType dbType) {
    switch (dbType) {
      case DatabaseType.firestore:
        return _createFirestoreQueryService<T>();
      case DatabaseType.sqlite:
        throw UnimplementedError(
          'Supabase implementation is not yet available',
        );
    }
  }

  static T _createFirestoreQueryService<T>() {
    if (T == GroupQueryService) {
      return FirestoreGroupQueryService() as T;
    }
    if (T == PinQueryService) {
      return FirestorePinQueryService() as T;
    }
    if (T == TripEntryQueryService) {
      return FirestoreTripEntryQueryService() as T;
    }
    if (T == TaskQueryService) {
      return FirestoreTaskQueryService() as T;
    }
    if (T == MemberQueryService) {
      return FirestoreMemberQueryService() as T;
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
