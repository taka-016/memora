import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/repositories/group_event_repository.dart';
import 'package:memora/domain/repositories/group_repository.dart';
import 'package:memora/domain/repositories/member_event_repository.dart';
import 'package:memora/domain/repositories/member_invitation_repository.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';
import 'package:memora/infrastructure/config/database_type.dart';
import 'package:memora/infrastructure/config/database_type_provider.dart';
import 'package:memora/infrastructure/repositories/firestore_group_event_repository.dart';
import 'package:memora/infrastructure/repositories/firestore_group_repository.dart';
import 'package:memora/infrastructure/repositories/firestore_member_event_repository.dart';
import 'package:memora/infrastructure/repositories/firestore_member_invitation_repository.dart';
import 'package:memora/infrastructure/repositories/firestore_member_repository.dart';
import 'package:memora/infrastructure/repositories/firestore_trip_entry_repository.dart';

class RepositoryFactory {
  static T create<T extends Object>({required Ref ref}) {
    final dbType = ref.read(databaseTypeProvider);
    return _createRepositoryByType<T>(dbType);
  }

  static T createWithWidgetRef<T extends Object>({required WidgetRef ref}) {
    final dbType = ref.read(databaseTypeProvider);
    return _createRepositoryByType<T>(dbType);
  }

  static T _createRepositoryByType<T extends Object>(DatabaseType dbType) {
    switch (dbType) {
      case DatabaseType.firestore:
        return _createFirestoreRepository<T>();
      case DatabaseType.sqlite:
        throw UnimplementedError(
          'Supabase implementation is not yet available',
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
    throw ArgumentError('Unknown repository type: $T');
  }
}
