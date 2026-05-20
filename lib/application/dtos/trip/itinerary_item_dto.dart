import 'package:equatable/equatable.dart';
import 'package:memora/application/dtos/copy_with_helper.dart';

class ItineraryItemDto extends Equatable {
  const ItineraryItemDto({
    required this.id,
    required this.tripId,
    required this.name,
    this.startDateTime,
    this.endDateTime,
    this.memo,
  });

  final String id;
  final String tripId;
  final String name;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final String? memo;

  ItineraryItemDto copyWith({
    String? id,
    String? tripId,
    String? name,
    Object? startDateTime = copyWithPlaceholder,
    Object? endDateTime = copyWithPlaceholder,
    Object? memo = copyWithPlaceholder,
  }) {
    return ItineraryItemDto(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      name: name ?? this.name,
      startDateTime: resolveCopyWithValue<DateTime>(
        startDateTime,
        this.startDateTime,
        'startDateTime',
      ),
      endDateTime: resolveCopyWithValue<DateTime>(
        endDateTime,
        this.endDateTime,
        'endDateTime',
      ),
      memo: resolveCopyWithValue<String>(memo, this.memo, 'memo'),
    );
  }

  @override
  List<Object?> get props => [
    id,
    tripId,
    name,
    startDateTime,
    endDateTime,
    memo,
  ];
}
