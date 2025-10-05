import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/pin/pin_dto.dart';
import 'package:memora/application/interfaces/pin_query_service.dart';
import 'package:memora/core/app_logger.dart';

class FirestorePinQueryService implements PinQueryService {
  FirestorePinQueryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<PinDto>> getPinsByMemberId(String memberId) async {
    try {
      final groupIds = await _getGroupIdsByMemberId(memberId);
      if (groupIds.isEmpty) {
        return [];
      }

      final List<PinDto> pins = [];
      for (final groupId in groupIds) {
        final groupPins = await _getPinsByGroupId(groupId);
        pins.addAll(groupPins);
      }

      return pins;
    } catch (e, stack) {
      logger.e(
        'FirestorePinQueryService.getPinsByMemberId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  Future<List<String>> _getGroupIdsByMemberId(String memberId) async {
    final List<String> groupIds = [];
    final Set<String> groupIdSet = {};

    final adminGroupsSnapshot = await _firestore
        .collection('groups')
        .where('ownerId', isEqualTo: memberId)
        .get();

    for (final doc in adminGroupsSnapshot.docs) {
      if (groupIdSet.add(doc.id)) {
        groupIds.add(doc.id);
      }
    }

    final memberGroupsSnapshot = await _firestore
        .collection('group_members')
        .where('memberId', isEqualTo: memberId)
        .get();

    for (final doc in memberGroupsSnapshot.docs) {
      final data = doc.data();
      final groupId = data['groupId'] as String?;
      if (groupId != null && groupId.isNotEmpty && groupIdSet.add(groupId)) {
        groupIds.add(groupId);
      }
    }

    return groupIds;
  }

  Future<List<PinDto>> _getPinsByGroupId(String groupId) async {
    final pinsSnapshot = await _firestore
        .collection('pins')
        .where('groupId', isEqualTo: groupId)
        .get();

    return pinsSnapshot.docs.map((doc) {
      final data = doc.data();
      return PinDto(
        pinId: data['pinId'] as String? ?? doc.id,
        tripId: data['tripId'] as String?,
        groupId: data['groupId'] as String? ?? groupId,
        latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
        locationName: data['locationName'] as String?,
        visitStartDate: _timestampToDateTime(data['visitStartDate']),
        visitEndDate: _timestampToDateTime(data['visitEndDate']),
        visitMemo: data['visitMemo'] as String?,
      );
    }).toList();
  }

  DateTime? _timestampToDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }
}
