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

    test('同じプロパティを持つインスタンス同士は等価である', () {
      final participant1 = TripParticipant(
        id: 'tp001',
        tripId: 'trip001',
        memberId: 'member001',
      );
      final participant2 = TripParticipant(
        id: 'tp001',
        tripId: 'trip001',
        memberId: 'member001',
      );
      expect(participant1, equals(participant2));
    });

    test('copyWithメソッドが正しく動作する', () {
      final participant = TripParticipant(
        id: 'tp001',
        tripId: 'trip001',
        memberId: 'member001',
      );
      final updatedParticipant = participant.copyWith(
        tripId: 'trip002',
        memberId: 'member002',
      );
      expect(updatedParticipant.id, 'tp001');
      expect(updatedParticipant.tripId, 'trip002');
      expect(updatedParticipant.memberId, 'member002');
    });
  });
}
