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
    required TripEntryQueryService tripEntryQueryService,
    required ItineraryItemQueryService itineraryItemQueryService,
    required AppClock clock,
  }) : _tripEntryQueryService = tripEntryQueryService,
       _itineraryItemQueryService = itineraryItemQueryService,
       _clock = clock;

  final TripEntryQueryService _tripEntryQueryService;
  final ItineraryItemQueryService _itineraryItemQueryService;
  final AppClock _clock;

  Future<AndroidWidgetItineraryCacheDto> execute({
    required String groupId,
    String? selectedTripId,
  }) async {
    final trips = await _tripEntryQueryService.getTripEntriesByGroupId(
      groupId,
      orderBy: const [OrderBy('startDate', descending: false)],
    );
    final sortedTrips = [...trips]..sort(_compareTripsByStartDate);
    final selectedTrip = _selectTrip(sortedTrips, selectedTripId);
    final cachedTrips = _selectCacheRange(sortedTrips, selectedTrip);
    final tripCaches = <AndroidWidgetTripCacheDto>[];

    for (final trip in cachedTrips) {
      final items = await _itineraryItemQueryService.getItineraryItemsByTripId(
        trip.id,
        orderBy: const [
          OrderBy('startDateTime', descending: false),
          OrderBy('endDateTime', descending: false),
        ],
      );
      tripCaches.add(_toTripCache(trip, items));
    }

    return AndroidWidgetItineraryCacheDto(
      version: 1,
      groupId: groupId,
      selectedTripId: selectedTrip?.id,
      lastUpdatedAt: _clock.now(),
      trips: tripCaches,
    );
  }

  TripEntryDto? _selectTrip(List<TripEntryDto> trips, String? selectedTripId) {
    if (selectedTripId != null) {
      for (final trip in trips) {
        if (trip.id == selectedTripId) {
          return trip;
        }
      }
    }

    final today = _dateOnly(_clock.now());
    for (final trip in trips) {
      final startDate = trip.startDate;
      if (startDate != null && !_dateOnly(startDate).isBefore(today)) {
        return trip;
      }
    }
    return trips.lastOrNull;
  }

  List<TripEntryDto> _selectCacheRange(
    List<TripEntryDto> trips,
    TripEntryDto? selectedTrip,
  ) {
    if (selectedTrip == null) {
      return [];
    }

    final selectedIndex = trips.indexWhere(
      (trip) => trip.id == selectedTrip.id,
    );
    if (selectedIndex < 0) {
      return [];
    }

    final startIndex = selectedIndex - 1 < 0 ? 0 : selectedIndex - 1;
    final endExclusive = selectedIndex + 4 > trips.length
        ? trips.length
        : selectedIndex + 4;
    return trips.sublist(startIndex, endExclusive);
  }

  AndroidWidgetTripCacheDto _toTripCache(
    TripEntryDto trip,
    List<ItineraryItemDto> itineraryItems,
  ) {
    final sortedItems = [...itineraryItems]..sort(_compareItineraryItems);
    return AndroidWidgetTripCacheDto(
      id: trip.id,
      name: trip.name?.isNotEmpty == true ? trip.name! : '名称未設定',
      periodLabel: _formatPeriodLabel(trip.startDate, trip.endDate),
      startDate: trip.startDate,
      endDate: trip.endDate,
      itineraryItems: sortedItems
          .map(
            (item) => AndroidWidgetItineraryItemCacheDto(
              id: item.id,
              name: item.name,
              timeLabel: _formatTimeLabel(item.startDateTime, item.endDateTime),
              startDateTime: item.startDateTime,
              endDateTime: item.endDateTime,
              memo: item.memo,
            ),
          )
          .toList(),
    );
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
    final endLabel = _isSameDate(startDateTime, endDateTime)
        ? _formatTime(endDateTime)
        : _formatDateTime(endDateTime);
    return '${_formatDateTime(startDateTime)} - $endLabel';
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
