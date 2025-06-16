import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/trip_entry_repository.dart';
import '../../domain/entities/trip_entry.dart';
import '../mappers/firestore_trip_entry_mapper.dart';

class FirestoreTripEntryRepository implements TripEntryRepository {
  final FirebaseFirestore _firestore;

  FirestoreTripEntryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveTripEntry(TripEntry tripEntry) async {
    await _firestore.collection('trip_entries').add(
      FirestoreTripEntryMapper.toFirestore(tripEntry),
    );
  }

  @override
  Future<List<TripEntry>> getTripEntries() async {
    try {
      final snapshot = await _firestore.collection('trip_entries').get();
      return snapshot.docs
          .map((doc) => FirestoreTripEntryMapper.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> deleteTripEntry(String tripId) async {
    await _firestore.collection('trip_entries').doc(tripId).delete();
  }

  @override
  Future<TripEntry?> getTripEntryById(String tripId) async {
    try {
      final doc = await _firestore.collection('trip_entries').doc(tripId).get();
      if (doc.exists) {
        return FirestoreTripEntryMapper.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}