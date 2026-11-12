import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/infrastructure/services/firestore_app_availability_source.dart';

import 'firestore_app_availability_source_test.mocks.dart';

@GenerateMocks([FirebaseFirestore, DocumentReference, DocumentSnapshot])
void main() {
  test('公開設定をサーバーから取得して最低ビルドと停止フラグを読み取る', () async {
    final firestore = MockFirebaseFirestore();
    final document = MockDocumentReference<Map<String, dynamic>>();
    final snapshot = MockDocumentSnapshot<Map<String, dynamic>>();
    when(firestore.doc('app_settings/availability')).thenReturn(document);
    when(document.get(any)).thenAnswer((_) async => snapshot);
    when(snapshot.data())
        .thenReturn({'minimumBuildNumber': 12, 'isMaintenance': true});
    final source = FirestoreAppAvailabilitySource(firestore: firestore);
    final settings = await source.load();
    expect(settings.minimumBuildNumber, 12);
    expect(settings.isMaintenance, isTrue);
    final options =
        verify(document.get(captureAny)).captured.single as GetOptions;
    expect(options.source, Source.server);
  });

  test('設定文書が未作成なら通常利用の設定として扱う', () async {
    final firestore = MockFirebaseFirestore();
    final document = MockDocumentReference<Map<String, dynamic>>();
    final snapshot = MockDocumentSnapshot<Map<String, dynamic>>();
    when(firestore.doc('app_settings/availability')).thenReturn(document);
    when(document.get(any)).thenAnswer((_) async => snapshot);
    when(snapshot.data()).thenReturn(null);
    final settings = await FirestoreAppAvailabilitySource(firestore: firestore)
        .load();
    expect(settings.minimumBuildNumber, 0);
    expect(settings.isMaintenance, isFalse);
  });
}
