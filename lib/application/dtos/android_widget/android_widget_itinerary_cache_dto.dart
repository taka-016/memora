import 'package:equatable/equatable.dart';

class AndroidWidgetItineraryCacheDto extends Equatable {
  const AndroidWidgetItineraryCacheDto({
    required this.version,
    required this.groupId,
    required this.selectedTripId,
    required this.lastUpdatedAt,
    required this.trips,
  });

  final int version;
  final String groupId;
  final String? selectedTripId;
  final DateTime lastUpdatedAt;
  final List<AndroidWidgetTripCacheDto> trips;

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'groupId': groupId,
      'selectedTripId': selectedTripId,
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'trips': trips.map((trip) => trip.toJson()).toList(),
    };
  }

  factory AndroidWidgetItineraryCacheDto.fromJson(Map<String, dynamic> json) {
    return AndroidWidgetItineraryCacheDto(
      version: json['version'] as int? ?? 1,
      groupId: json['groupId'] as String? ?? '',
      selectedTripId: json['selectedTripId'] as String?,
      lastUpdatedAt:
          DateTime.tryParse(json['lastUpdatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      trips: ((json['trips'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AndroidWidgetTripCacheDto.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    version,
    groupId,
    selectedTripId,
    lastUpdatedAt,
    trips,
  ];
}

class AndroidWidgetTripCacheDto extends Equatable {
  const AndroidWidgetTripCacheDto({
    required this.id,
    required this.name,
    required this.periodLabel,
    required this.startDate,
    required this.endDate,
    required this.itineraryItems,
  });

  final String id;
  final String name;
  final String periodLabel;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<AndroidWidgetItineraryItemCacheDto> itineraryItems;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'periodLabel': periodLabel,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'itineraryItems': itineraryItems.map((item) => item.toJson()).toList(),
    };
  }

  factory AndroidWidgetTripCacheDto.fromJson(Map<String, dynamic> json) {
    return AndroidWidgetTripCacheDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      periodLabel: json['periodLabel'] as String? ?? '',
      startDate: DateTime.tryParse(json['startDate'] as String? ?? ''),
      endDate: DateTime.tryParse(json['endDate'] as String? ?? ''),
      itineraryItems: ((json['itineraryItems'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AndroidWidgetItineraryItemCacheDto.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    periodLabel,
    startDate,
    endDate,
    itineraryItems,
  ];
}

class AndroidWidgetItineraryItemCacheDto extends Equatable {
  const AndroidWidgetItineraryItemCacheDto({
    required this.id,
    required this.name,
    required this.timeLabel,
    required this.startDateTime,
    required this.endDateTime,
    this.memo,
  });

  final String id;
  final String name;
  final String timeLabel;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final String? memo;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'timeLabel': timeLabel,
      'startDateTime': startDateTime?.toIso8601String(),
      'endDateTime': endDateTime?.toIso8601String(),
      'memo': memo,
    };
  }

  factory AndroidWidgetItineraryItemCacheDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return AndroidWidgetItineraryItemCacheDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      timeLabel: json['timeLabel'] as String? ?? '',
      startDateTime: DateTime.tryParse(json['startDateTime'] as String? ?? ''),
      endDateTime: DateTime.tryParse(json['endDateTime'] as String? ?? ''),
      memo: json['memo'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    timeLabel,
    startDateTime,
    endDateTime,
    memo,
  ];
}
