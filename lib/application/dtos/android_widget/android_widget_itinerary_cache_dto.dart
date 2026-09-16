import 'package:equatable/equatable.dart';

class AndroidWidgetItineraryCacheDto extends Equatable {
  const AndroidWidgetItineraryCacheDto({
    required this.version,
    required this.groupId,
    required this.selectedItineraryDateId,
    required this.lastUpdatedAt,
    required this.itineraryDates,
  });

  final int version;
  final String groupId;
  final String? selectedItineraryDateId;
  final DateTime lastUpdatedAt;
  final List<AndroidWidgetItineraryDateCacheDto> itineraryDates;

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'groupId': groupId,
      'selectedItineraryDateId': selectedItineraryDateId,
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'itineraryDates': itineraryDates
          .map((itineraryDate) => itineraryDate.toJson())
          .toList(),
    };
  }

  factory AndroidWidgetItineraryCacheDto.fromJson(Map<String, dynamic> json) {
    return AndroidWidgetItineraryCacheDto(
      version: json['version'] as int? ?? 1,
      groupId: json['groupId'] as String? ?? '',
      selectedItineraryDateId: json['selectedItineraryDateId'] as String?,
      lastUpdatedAt:
          DateTime.tryParse(json['lastUpdatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      itineraryDates: ((json['itineraryDates'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AndroidWidgetItineraryDateCacheDto.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    version,
    groupId,
    selectedItineraryDateId,
    lastUpdatedAt,
    itineraryDates,
  ];
}

class AndroidWidgetItineraryDateCacheDto extends Equatable {
  const AndroidWidgetItineraryDateCacheDto({
    required this.id,
    required this.tripId,
    required this.tripName,
    required this.tripPeriodLabel,
    required this.dateLabel,
    required this.date,
    required this.itineraryItems,
  });

  final String id;
  final String tripId;
  final String tripName;
  final String tripPeriodLabel;
  final String dateLabel;
  final DateTime date;
  final List<AndroidWidgetItineraryItemCacheDto> itineraryItems;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'tripName': tripName,
      'tripPeriodLabel': tripPeriodLabel,
      'dateLabel': dateLabel,
      'date': date.toIso8601String(),
      'itineraryItems': itineraryItems.map((item) => item.toJson()).toList(),
    };
  }

  factory AndroidWidgetItineraryDateCacheDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return AndroidWidgetItineraryDateCacheDto(
      id: json['id'] as String? ?? '',
      tripId: json['tripId'] as String? ?? '',
      tripName: json['tripName'] as String? ?? '',
      tripPeriodLabel: json['tripPeriodLabel'] as String? ?? '',
      dateLabel: json['dateLabel'] as String? ?? '',
      date:
          DateTime.tryParse(json['date'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      itineraryItems: ((json['itineraryItems'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AndroidWidgetItineraryItemCacheDto.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    tripId,
    tripName,
    tripPeriodLabel,
    dateLabel,
    date,
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
  });

  final String id;
  final String name;
  final String timeLabel;
  final DateTime? startDateTime;
  final DateTime? endDateTime;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'timeLabel': timeLabel,
      'startDateTime': startDateTime?.toIso8601String(),
      'endDateTime': endDateTime?.toIso8601String(),
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
    );
  }

  @override
  List<Object?> get props => [id, name, timeLabel, startDateTime, endDateTime];
}
