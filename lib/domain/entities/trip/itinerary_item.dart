import 'package:equatable/equatable.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

class ItineraryItem extends Equatable {
  ItineraryItem({
    required this.id,
    required this.tripId,
    required this.name,
    this.startDateTime,
    this.endDateTime,
    this.memo,
    this.locationId,
  }) {
    _validate();
  }

  final String id;
  final String tripId;
  final String name;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final String? memo;
  final String? locationId;

  ItineraryItem copyWith({
    String? id,
    String? tripId,
    String? name,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? memo,
    String? locationId,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      name: name ?? this.name,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      memo: memo ?? this.memo,
      locationId: locationId ?? this.locationId,
    );
  }

  void _validate() {
    if (name.trim().isEmpty) {
      throw ValidationException('旅程項目名は必須です');
    }
    if (startDateTime != null &&
        endDateTime != null &&
        endDateTime!.isBefore(startDateTime!)) {
      throw ValidationException('旅程項目の終了日時は開始日時以降でなければなりません');
    }
  }

  @override
  List<Object?> get props => [
    id,
    tripId,
    name,
    startDateTime,
    endDateTime,
    memo,
    locationId,
  ];
}
