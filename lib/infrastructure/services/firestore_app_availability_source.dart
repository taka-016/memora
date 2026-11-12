import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/models/app_availability.dart';
import 'package:memora/application/services/app_availability_source.dart';

class FirestoreAppAvailabilitySource implements AppAvailabilitySource {
  FirestoreAppAvailabilitySource({required this._firestore});

  final FirebaseFirestore _firestore;

  @override
  Future<AppAvailabilitySettings> load() async {
    final snapshot = await _firestore
        .doc('app_settings/availability')
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 10));
    final data = snapshot.data();
    if (data == null) {
      return const AppAvailabilitySettings(
        minimumBuildNumber: 0,
        isMaintenance: false,
      );
    }
    return AppAvailabilitySettings(
      minimumBuildNumber: data['minimumBuildNumber'] as int,
      isMaintenance: data['isMaintenance'] as bool,
    );
  }
}
