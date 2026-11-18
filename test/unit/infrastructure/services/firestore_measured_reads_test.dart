import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/infrastructure/services/firestore_measured_reads.dart';
import 'package:memora/infrastructure/services/firestore_read_probe.dart';
import '../../../helpers/test_exception.dart';
import '../queries/calendar/firestore_calendar_watch_query_service_test.mocks.dart';

void main() {
  tearDown(() => FirestoreReadProbe.current = null);
  test('同じ条件のQueryでも取得先を分け元の取得オプションで実行する', () async {
    final events = <Map<String, Object?>>[];
    FirestoreReadProbe.current = FirestoreReadProbe(runId: 'run', operationId: () => 'open', emit: events.add);
    const options = GetOptions(source: Source.cache);
    final query = MockQuery();
    when(query.parameters).thenReturn({});
    when(query.get(options)).thenThrow(TestException('取得失敗'));
    for (final target in ['groups', 'members']) {
      await expectLater(query.measuredGet('site', options: options, target: target), throwsA(isA<TestException>()));
    }
    expect(events.where((event) => event['phase'] == 'start').map((event) => event['target']), ['groups', 'members']);
    expect(events.where((event) => event['phase'] == 'error'), hasLength(2));
    verify(query.get(options)).called(2);
  });
}
