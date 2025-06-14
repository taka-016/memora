import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip_participant.dart';

void main() {
  group('TripParticipant', () {
    test('インスタンス生成が正しく行われる', () {
      final participant = TripParticipant(
        id: 'tp001',
        tripId: 'trip001',
        memberId: 'member001',
      );
      expect(participant.id, 'tp001');
      expect(participant.tripId, 'trip001');
      expect(participant.memberId, 'member001');
    });
  });
}
