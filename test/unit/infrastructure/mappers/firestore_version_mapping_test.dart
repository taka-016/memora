import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/infrastructure/mappers/member/firestore_member_mapper.dart';
import 'package:memora/application/mappers/member/member_mapper.dart';
import 'package:memora/infrastructure/mappers/member/firestore_member_invitation_mapper.dart';
import 'package:memora/application/mappers/member/member_invitation_mapper.dart';
import 'package:memora/infrastructure/mappers/member/firestore_member_event_mapper.dart';
import 'package:memora/application/mappers/member/member_event_mapper.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_mapper.dart';
import 'package:memora/application/mappers/group/group_mapper.dart';
import 'package:memora/infrastructure/mappers/group/firestore_group_event_mapper.dart';
import 'package:memora/application/mappers/group/group_event_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_trip_entry_mapper.dart';
import 'package:memora/application/mappers/trip/trip_entry_mapper.dart';
import 'package:memora/infrastructure/mappers/calendar/firestore_calendar_event_mapper.dart';
import 'package:memora/application/mappers/calendar/calendar_event_mapper.dart';
import 'package:memora/infrastructure/mappers/calendar/firestore_calendar_label_mapper.dart';
import 'package:memora/application/mappers/calendar/calendar_label_mapper.dart';
import 'package:memora/infrastructure/mappers/dvc/firestore_dvc_point_contract_mapper.dart';
import 'package:memora/application/mappers/dvc/dvc_point_contract_mapper.dart';

import 'firestore_version_mapping_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('Memberの編集バージョン', () {
    final fields = <String, dynamic>{
      'version': 7,
      'groupId': 'group',
      'labelId': 'label',
      'title': '予定',
      'name': '名前',
      'displayName': '名前',
      'color': '#112233',
      'isAllDay': true,
      'startDateTime': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'endDateTime': Timestamp.fromDate(DateTime.utc(2026, 1, 2)),
    };
    late MockDocumentSnapshot<Map<String, dynamic>> doc;
    setUp(() {
      doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('id');
      when(doc.data()).thenAnswer((_) => fields);
    });
    test('取得から編集と保存要求まで期待値を保持し保存時だけ次の値を送る', () {
      final dynamic dto = FirestoreMemberMapper.fromFirestore(doc);
      expect(dto.version, 7);
      final dynamic edited = dto.copyWith();
      final entity = MemberMapper.toEntity(edited);
      final dynamic restored = MemberMapper.toDto(entity);
      expect(restored.version, 7);
      expect(FirestoreMemberMapper.toCreateFirestore(entity)['version'], 1);
      expect(FirestoreMemberMapper.toUpdateFirestore(entity)['version'], 8);
      expect(FirestoreMemberMapper.toUpdateFirestore(entity)['version'], 8);
      expect(dto.version, 7);
    });
    test('未設定のバージョンを取得時に補完しない', () {
      final saved = fields.remove('version');
      addTearDown(() => fields['version'] = saved);
      final dynamic dto = FirestoreMemberMapper.fromFirestore(doc);
      expect(dto.version, isNull);
    });
  });
  group('MemberInvitationの編集バージョン', () {
    final fields = <String, dynamic>{
      'version': 7,
      'groupId': 'group',
      'labelId': 'label',
      'title': '予定',
      'name': '名前',
      'displayName': '名前',
      'color': '#112233',
      'isAllDay': true,
      'startDateTime': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'endDateTime': Timestamp.fromDate(DateTime.utc(2026, 1, 2)),
    };
    late MockDocumentSnapshot<Map<String, dynamic>> doc;
    setUp(() {
      doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('id');
      when(doc.data()).thenAnswer((_) => fields);
    });
    test('取得から編集と保存要求まで期待値を保持し保存時だけ次の値を送る', () {
      final dynamic dto = FirestoreMemberInvitationMapper.fromFirestore(doc);
      expect(dto.version, 7);
      final dynamic edited = dto.copyWith();
      final entity = MemberInvitationMapper.toEntity(edited);
      final dynamic restored = MemberInvitationMapper.toDto(entity);
      expect(restored.version, 7);
      expect(
        FirestoreMemberInvitationMapper.toCreateFirestore(entity)['version'],
        1,
      );
      expect(
        FirestoreMemberInvitationMapper.toUpdateFirestore(entity)['version'],
        8,
      );
      expect(
        FirestoreMemberInvitationMapper.toUpdateFirestore(entity)['version'],
        8,
      );
      expect(dto.version, 7);
    });
    test('未設定のバージョンを取得時に補完しない', () {
      final saved = fields.remove('version');
      addTearDown(() => fields['version'] = saved);
      final dynamic dto = FirestoreMemberInvitationMapper.fromFirestore(doc);
      expect(dto.version, isNull);
    });
  });
  group('MemberEventの編集バージョン', () {
    final fields = <String, dynamic>{
      'version': 7,
      'groupId': 'group',
      'labelId': 'label',
      'title': '予定',
      'name': '名前',
      'displayName': '名前',
      'color': '#112233',
      'isAllDay': true,
      'startDateTime': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'endDateTime': Timestamp.fromDate(DateTime.utc(2026, 1, 2)),
    };
    late MockDocumentSnapshot<Map<String, dynamic>> doc;
    setUp(() {
      doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('id');
      when(doc.data()).thenAnswer((_) => fields);
    });
    test('取得から編集と保存要求まで期待値を保持し保存時だけ次の値を送る', () {
      final dynamic dto = FirestoreMemberEventMapper.fromFirestore(doc);
      expect(dto.version, 7);
      final dynamic edited = dto.copyWith();
      final entity = MemberEventMapper.toEntity(edited);
      final dynamic restored = MemberEventMapper.toDto(entity);
      expect(restored.version, 7);
      expect(
        FirestoreMemberEventMapper.toCreateFirestore(entity)['version'],
        1,
      );
      expect(
        FirestoreMemberEventMapper.toUpdateFirestore(entity)['version'],
        8,
      );
      expect(
        FirestoreMemberEventMapper.toUpdateFirestore(entity)['version'],
        8,
      );
      expect(dto.version, 7);
    });
    test('未設定のバージョンを取得時に補完しない', () {
      final saved = fields.remove('version');
      addTearDown(() => fields['version'] = saved);
      final dynamic dto = FirestoreMemberEventMapper.fromFirestore(doc);
      expect(dto.version, isNull);
    });
  });
  group('Groupの編集バージョン', () {
    final fields = <String, dynamic>{
      'version': 7,
      'groupId': 'group',
      'labelId': 'label',
      'title': '予定',
      'name': '名前',
      'displayName': '名前',
      'color': '#112233',
      'isAllDay': true,
      'startDateTime': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'endDateTime': Timestamp.fromDate(DateTime.utc(2026, 1, 2)),
    };
    late MockDocumentSnapshot<Map<String, dynamic>> doc;
    setUp(() {
      doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('id');
      when(doc.data()).thenAnswer((_) => fields);
    });
    test('取得から編集と保存要求まで期待値を保持し保存時だけ次の値を送る', () {
      final dynamic dto = FirestoreGroupMapper.fromFirestore(doc);
      expect(dto.version, 7);
      final dynamic edited = dto.copyWith();
      final entity = GroupMapper.toEntity(edited);
      final dynamic restored = entity;
      expect(restored.version, 7);
      expect(FirestoreGroupMapper.toCreateFirestore(entity)['version'], 1);
      expect(FirestoreGroupMapper.toUpdateFirestore(entity)['version'], 8);
      expect(FirestoreGroupMapper.toUpdateFirestore(entity)['version'], 8);
      expect(dto.version, 7);
    });
    test('未設定のバージョンを取得時に補完しない', () {
      final saved = fields.remove('version');
      addTearDown(() => fields['version'] = saved);
      final dynamic dto = FirestoreGroupMapper.fromFirestore(doc);
      expect(dto.version, isNull);
    });
  });
  group('GroupEventの編集バージョン', () {
    final fields = <String, dynamic>{
      'version': 7,
      'groupId': 'group',
      'labelId': 'label',
      'title': '予定',
      'name': '名前',
      'displayName': '名前',
      'color': '#112233',
      'isAllDay': true,
      'startDateTime': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'endDateTime': Timestamp.fromDate(DateTime.utc(2026, 1, 2)),
    };
    late MockDocumentSnapshot<Map<String, dynamic>> doc;
    setUp(() {
      doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('id');
      when(doc.data()).thenAnswer((_) => fields);
    });
    test('取得から編集と保存要求まで期待値を保持し保存時だけ次の値を送る', () {
      final dynamic dto = FirestoreGroupEventMapper.fromFirestore(doc);
      expect(dto.version, 7);
      final dynamic edited = dto.copyWith();
      final entity = GroupEventMapper.toEntity(edited);
      final dynamic restored = GroupEventMapper.toDto(entity);
      expect(restored.version, 7);
      expect(FirestoreGroupEventMapper.toCreateFirestore(entity)['version'], 1);
      expect(FirestoreGroupEventMapper.toUpdateFirestore(entity)['version'], 8);
      expect(FirestoreGroupEventMapper.toUpdateFirestore(entity)['version'], 8);
      expect(dto.version, 7);
    });
    test('未設定のバージョンを取得時に補完しない', () {
      final saved = fields.remove('version');
      addTearDown(() => fields['version'] = saved);
      final dynamic dto = FirestoreGroupEventMapper.fromFirestore(doc);
      expect(dto.version, isNull);
    });
  });
  group('TripEntryの編集バージョン', () {
    final fields = <String, dynamic>{
      'version': 7,
      'groupId': 'group',
      'labelId': 'label',
      'title': '予定',
      'name': '名前',
      'displayName': '名前',
      'color': '#112233',
      'isAllDay': true,
      'startDateTime': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'endDateTime': Timestamp.fromDate(DateTime.utc(2026, 1, 2)),
    };
    late MockDocumentSnapshot<Map<String, dynamic>> doc;
    setUp(() {
      doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('id');
      when(doc.data()).thenAnswer((_) => fields);
    });
    test('取得から編集と保存要求まで期待値を保持し保存時だけ次の値を送る', () {
      final dynamic dto = FirestoreTripEntryMapper.fromFirestore(
        doc,
        fallbackTripYear: 2026,
      );
      expect(dto.version, 7);
      final dynamic edited = dto.copyWith();
      final entity = TripEntryMapper.toEntity(edited);
      final dynamic restored = entity;
      expect(restored.version, 7);
      expect(FirestoreTripEntryMapper.toCreateFirestore(entity)['version'], 1);
      expect(FirestoreTripEntryMapper.toUpdateFirestore(entity)['version'], 8);
      expect(FirestoreTripEntryMapper.toUpdateFirestore(entity)['version'], 8);
      expect(dto.version, 7);
    });
    test('未設定のバージョンを取得時に補完しない', () {
      final saved = fields.remove('version');
      addTearDown(() => fields['version'] = saved);
      final dynamic dto = FirestoreTripEntryMapper.fromFirestore(
        doc,
        fallbackTripYear: 2026,
      );
      expect(dto.version, isNull);
    });
  });
  group('CalendarEventの編集バージョン', () {
    final fields = <String, dynamic>{
      'version': 7,
      'groupId': 'group',
      'labelId': 'label',
      'title': '予定',
      'name': '名前',
      'displayName': '名前',
      'color': '#112233',
      'isAllDay': true,
      'startDateTime': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'endDateTime': Timestamp.fromDate(DateTime.utc(2026, 1, 2)),
    };
    late MockDocumentSnapshot<Map<String, dynamic>> doc;
    setUp(() {
      doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('id');
      when(doc.data()).thenAnswer((_) => fields);
    });
    test('取得から編集と保存要求まで期待値を保持し保存時だけ次の値を送る', () {
      final dynamic dto = FirestoreCalendarEventMapper.fromFirestore(doc);
      expect(dto.version, 7);
      final dynamic edited = dto.copyWith();
      final entity = CalendarEventMapper.toEntity(edited);
      final dynamic restored = CalendarEventMapper.toDto(entity);
      expect(restored.version, 7);
      expect(
        FirestoreCalendarEventMapper.toCreateFirestore(entity)['version'],
        1,
      );
      expect(
        FirestoreCalendarEventMapper.toUpdateFirestore(entity)['version'],
        8,
      );
      expect(
        FirestoreCalendarEventMapper.toUpdateFirestore(entity)['version'],
        8,
      );
      expect(dto.version, 7);
    });
    test('未設定のバージョンを取得時に補完しない', () {
      final saved = fields.remove('version');
      addTearDown(() => fields['version'] = saved);
      final dynamic dto = FirestoreCalendarEventMapper.fromFirestore(doc);
      expect(dto.version, isNull);
    });
  });
  group('CalendarLabelの編集バージョン', () {
    final fields = <String, dynamic>{
      'version': 7,
      'groupId': 'group',
      'labelId': 'label',
      'title': '予定',
      'name': '名前',
      'displayName': '名前',
      'color': '#112233',
      'isAllDay': true,
      'startDateTime': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'endDateTime': Timestamp.fromDate(DateTime.utc(2026, 1, 2)),
    };
    late MockDocumentSnapshot<Map<String, dynamic>> doc;
    setUp(() {
      doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('id');
      when(doc.data()).thenAnswer((_) => fields);
    });
    test('取得から編集と保存要求まで期待値を保持し保存時だけ次の値を送る', () {
      final dynamic dto = FirestoreCalendarLabelMapper.fromFirestore(doc);
      expect(dto.version, 7);
      final dynamic edited = dto.copyWith();
      final entity = CalendarLabelMapper.toEntity(edited);
      final dynamic restored = CalendarLabelMapper.toDto(entity);
      expect(restored.version, 7);
      expect(
        FirestoreCalendarLabelMapper.toCreateFirestore(entity)['version'],
        1,
      );
      expect(
        FirestoreCalendarLabelMapper.toUpdateFirestore(entity)['version'],
        8,
      );
      expect(
        FirestoreCalendarLabelMapper.toUpdateFirestore(entity)['version'],
        8,
      );
      expect(dto.version, 7);
    });
    test('未設定のバージョンを取得時に補完しない', () {
      final saved = fields.remove('version');
      addTearDown(() => fields['version'] = saved);
      final dynamic dto = FirestoreCalendarLabelMapper.fromFirestore(doc);
      expect(dto.version, isNull);
    });
  });
  group('DvcPointContractの編集バージョン', () {
    final fields = <String, dynamic>{
      'version': 7,
      'groupId': 'group',
      'labelId': 'label',
      'title': '予定',
      'name': '名前',
      'displayName': '名前',
      'color': '#112233',
      'isAllDay': true,
      'startDateTime': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'endDateTime': Timestamp.fromDate(DateTime.utc(2026, 1, 2)),
    };
    late MockDocumentSnapshot<Map<String, dynamic>> doc;
    setUp(() {
      doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('id');
      when(doc.data()).thenAnswer((_) => fields);
    });
    test('取得から編集と保存要求まで期待値を保持し保存時だけ次の値を送る', () {
      final dynamic dto = FirestoreDvcPointContractMapper.fromFirestore(doc);
      expect(dto.version, 7);
      final dynamic edited = dto.copyWith();
      final entity = DvcPointContractMapper.toEntity(edited);
      final dynamic restored = DvcPointContractMapper.toDto(entity);
      expect(restored.version, 7);
      expect(
        FirestoreDvcPointContractMapper.toCreateFirestore(entity)['version'],
        1,
      );
      expect(dto.version, 7);
    });
    test('未設定のバージョンを取得時に補完しない', () {
      final saved = fields.remove('version');
      addTearDown(() => fields['version'] = saved);
      final dynamic dto = FirestoreDvcPointContractMapper.fromFirestore(doc);
      expect(dto.version, isNull);
    });
  });
}
