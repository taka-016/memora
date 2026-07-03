import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/itinerary_item_query_service.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getAndroidWidgetItineraryCacheUsecaseProvider =
    Provider<GetAndroidWidgetItineraryCacheUsecase>((ref) {
      return GetAndroidWidgetItineraryCacheUsecase(
        tripEntryQueryService: ref.watch(tripEntryQueryServiceProvider),
        itineraryItemQueryService: ref.watch(itineraryItemQueryServiceProvider),
        clock: ref.watch(appClockProvider),
      );
    });

class GetAndroidWidgetItineraryCacheUsecase {
  const GetAndroidWidgetItineraryCacheUsecase({
    required this._tripEntryQueryService,
    required this._itineraryItemQueryService,
    required this._clock,
  });

  final TripEntryQueryService _tripEntryQueryService;
  final ItineraryItemQueryService _itineraryItemQueryService;
  final AppClock _clock;

  Future<AndroidWidgetItineraryCacheDto> execute({
    required String groupId,
    String? selectedItineraryDateId,
  }) async {
    final trips = await _tripEntryQueryService.getTripEntriesByGroupId(groupId);
    final sortedTrips = [...trips]..sort(_compareTripsByStartDate);
    final allItineraryDates = <AndroidWidgetItineraryDateCacheDto>[];

    for (final trip in sortedTrips) {
      final items = await _itineraryItemQueryService.getItineraryItemsByTripId(
        trip.id,
        orderBy: const [
          OrderBy('startDateTime', descending: false),
          OrderBy('endDateTime', descending: false),
        ],
      );
      allItineraryDates.addAll(_toItineraryDateCaches(trip, items));
    }

    allItineraryDates.sort(_compareItineraryDateCaches);
    final selectedItineraryDate = _selectItineraryDate(
      allItineraryDates,
      selectedItineraryDateId,
    );
    final cachedItineraryDates = _selectCacheRange(
      allItineraryDates,
      selectedItineraryDate,
    );

    return AndroidWidgetItineraryCacheDto(
      version: 1,
      groupId: groupId,
      selectedItineraryDateId: selectedItineraryDate?.id,
      lastUpdatedAt: _clock.now(),
      itineraryDates: cachedItineraryDates,
    );
  }

  AndroidWidgetItineraryDateCacheDto? _selectItineraryDate(
    List<AndroidWidgetItineraryDateCacheDto> itineraryDates,
    String? selectedItineraryDateId,
  ) {
    if (selectedItineraryDateId != null) {
      for (final itineraryDate in itineraryDates) {
        if (itineraryDate.id == selectedItineraryDateId) {
          return itineraryDate;
        }
      }
    }

    final today = _dateOnly(_clock.now());
    for (final itineraryDate in itineraryDates) {
      if (!itineraryDate.date.isBefore(today)) {
        return itineraryDate;
      }
    }
    return itineraryDates.lastOrNull;
  }

  List<AndroidWidgetItineraryDateCacheDto> _selectCacheRange(
    List<AndroidWidgetItineraryDateCacheDto> itineraryDates,
    AndroidWidgetItineraryDateCacheDto? selectedItineraryDate,
  ) {
    if (selectedItineraryDate == null) {
      return [];
    }

    final selectedIndex = itineraryDates.indexWhere(
      (itineraryDate) => itineraryDate.id == selectedItineraryDate.id,
    );
    if (selectedIndex < 0) {
      return [];
    }

    final startIndex = selectedIndex - 1 < 0 ? 0 : selectedIndex - 1;
    final endExclusive = selectedIndex + 4 > itineraryDates.length
        ? itineraryDates.length
        : selectedIndex + 4;
    return itineraryDates.sublist(startIndex, endExclusive);
  }

  List<AndroidWidgetItineraryDateCacheDto> _toItineraryDateCaches(
    TripEntryDto trip,
    List<ItineraryItemDto> itineraryItems,
  ) {
    final sortedItems = [...itineraryItems]..sort(_compareItineraryItems);
    final itemsByDate = <DateTime, List<ItineraryItemDto>>{};
    for (final item in sortedItems) {
      final startDateTime = item.startDateTime;
      if (startDateTime == null) {
        continue;
      }
      final date = _dateOnly(startDateTime);
      itemsByDate.putIfAbsent(date, () => []).add(item);
    }

    return itemsByDate.entries.map((entry) {
      return AndroidWidgetItineraryDateCacheDto(
        id: _buildItineraryDateId(trip.id, entry.key),
        tripId: trip.id,
        tripName: trip.name?.isNotEmpty == true ? trip.name! : '名称未設定',
        tripPeriodLabel: _formatPeriodLabel(trip.startDate, trip.endDate),
        dateLabel: _formatDate(entry.key),
        date: entry.key,
        itineraryItems: entry.value
            .map(
              (item) => AndroidWidgetItineraryItemCacheDto(
                id: item.id,
                name: item.name,
                timeLabel: _formatTimeLabel(
                  item.startDateTime,
                  item.endDateTime,
                ),
                startDateTime: item.startDateTime,
                endDateTime: item.endDateTime,
              ),
            )
            .toList(),
      );
    }).toList();
  }

  int _compareTripsByStartDate(TripEntryDto a, TripEntryDto b) {
    return _compareNullableDateTime(a.startDate, b.startDate);
  }

  int _compareItineraryItems(ItineraryItemDto a, ItineraryItemDto b) {
    final startComparison = _compareNullableDateTime(
      a.startDateTime,
      b.startDateTime,
    );
    if (startComparison != 0) {
      return startComparison;
    }
    return _compareNullableDateTime(a.endDateTime, b.endDateTime);
  }

  int _compareItineraryDateCaches(
    AndroidWidgetItineraryDateCacheDto a,
    AndroidWidgetItineraryDateCacheDto b,
  ) {
    final dateComparison = a.date.compareTo(b.date);
    if (dateComparison != 0) {
      return dateComparison;
    }
    return a.tripId.compareTo(b.tripId);
  }

  int _compareNullableDateTime(DateTime? a, DateTime? b) {
    if (a == null && b == null) {
      return 0;
    }
    if (a == null) {
      return 1;
    }
    if (b == null) {
      return -1;
    }
    return a.compareTo(b);
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _buildItineraryDateId(String tripId, DateTime date) {
    return '${tripId}_${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatPeriodLabel(DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) {
      return '期間未設定';
    }
    if (startDate == null) {
      return '${_formatDate(endDate!)}まで';
    }
    if (endDate == null) {
      return '${_formatDate(startDate)}から';
    }
    return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
  }

  String _formatTimeLabel(DateTime? startDateTime, DateTime? endDateTime) {
    if (startDateTime == null && endDateTime == null) {
      return '時刻未設定';
    }
    if (startDateTime == null) {
      return '${_formatDateTime(endDateTime!)}まで';
    }
    if (endDateTime == null) {
      return '${_formatDateTime(startDateTime)}から';
    }
    final startLabel = _formatTime(startDateTime);
    final endLabel = _isSameDate(startDateTime, endDateTime)
        ? _formatTime(endDateTime)
        : _formatDateTime(endDateTime);
    return '$startLabel - $endLabel';
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime value) {
    return '${value.year}/${value.month}/${value.day}';
  }

  String _formatDateTime(DateTime value) {
    return '${value.month}/${value.day} ${_formatTime(value)}';
  }

  String _formatTime(DateTime value) {
    return '${value.hour}:${value.minute.toString().padLeft(2, '0')}';
  }
}
