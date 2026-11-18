import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/services/firestore_app_availability_source.dart';

Future<Map<String, Object?>> executeQueryAction(
  String action,
  Map<String, dynamic> params,
  Map<String, dynamic> dataset,
  ProviderContainer container,
) async {
  String value(String key) => params[key] as String;
  switch (action) {
    case 'login':
      final account = (dataset['accounts'] as List)
          .cast<Map<String, dynamic>>()
          .singleWhere((account) => account['id'] == params['account']);
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: account['email'] as String,
        password: account['password'] as String,
      );
      return {'id': result.user!.uid};
    case 'logout':
      await FirebaseAuth.instance.signOut();
      return {'signedOut': FirebaseAuth.instance.currentUser == null};
    case 'availability':
      final result = await FirestoreAppAvailabilitySource(
        firestore: container.read(firebaseFirestoreProvider),
      ).load();
      return {
        'isMaintenance': result.isMaintenance,
        'minimumBuildNumber': result.minimumBuildNumber,
      };
    case 'currentMember':
      final result = await container
          .read(memberQueryServiceProvider)
          .getMemberByAccountId(value('accountId'));
      return {'id': result?.id};
    case 'group':
      final result = await container
          .read(groupQueryServiceProvider)
          .getGroupWithMembersById(value('groupId'));
      return {'id': result?.id, 'members': result?.members.length};
    case 'calendarEvents':
      final result = await container
          .read(calendarEventQueryServiceProvider)
          .getCalendarEventsByGroupId(
            value('groupId'),
            period: CalendarEventPeriod.forMonth(
              DateTime.parse(value('month')).toLocal(),
            ),
          );
      return {'count': result.length};
    case 'calendarLabels':
      final result = await container
          .read(calendarLabelQueryServiceProvider)
          .getCalendarLabelsByGroupId(value('groupId'));
      return {'count': result.length};
    case 'groupTimeline':
      final result = await container
          .read(groupEventQueryServiceProvider)
          .getGroupEventsByGroupId(value('groupId'));
      return {'count': result.length};
    case 'memberTimeline':
      final result = await container
          .read(memberEventQueryServiceProvider)
          .getMemberEventsByMemberIds(
            (params['memberIds'] as List).cast<String>(),
            groupId: value('groupId'),
          );
      return {'count': result.length};
    case 'trips':
      final result = await container
          .read(tripEntryQueryServiceProvider)
          .getTripEntriesByGroupId(value('groupId'));
      return {'count': result.length};
    case 'trip':
      final result = await container
          .read(tripEntryQueryServiceProvider)
          .getTripEntryById(value('tripId'));
      return {
        'id': result?.id,
        'locations': result?.locations?.length,
        'tasks': result?.tasks?.length,
        'itineraryItems': result?.itineraryItems?.length,
      };
    case 'mapLocations':
      final result = await container
          .read(locationQueryServiceProvider)
          .getLocationsByGroupId(value('groupId'));
      return {'count': result.length};
    case 'dvcContracts':
      final result = await container
          .read(dvcPointContractQueryServiceProvider)
          .getDvcPointContractsByGroupId(value('groupId'));
      return {'count': result.length};
    case 'dvcLimitedPoints':
      final result = await container
          .read(dvcLimitedPointQueryServiceProvider)
          .getDvcLimitedPointsByGroupId(value('groupId'));
      return {'count': result.length};
    case 'dvcUsages':
      final result = await container
          .read(dvcPointUsageQueryServiceProvider)
          .getDvcPointUsagesByGroupId(value('groupId'));
      return {'count': result.length};
    default:
      throw StateError('未登録の操作です: $action');
  }
}
