import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/domain/services/route_information_service.dart';
import 'package:memora/domain/value_objects/route/route_candidate.dart';
import 'package:memora/domain/value_objects/route/route_location.dart';
import 'package:memora/domain/value_objects/route/route_travel_mode.dart';

class RouteInfoSegmentState {
  RouteInfoSegmentState({
    required this.from,
    required this.to,
    required this.travelMode,
    this.candidate,
  });

  final PinDto from;
  final PinDto to;
  RouteTravelMode travelMode;
  RouteCandidate? candidate;
}

class RouteInfoDialogController extends ChangeNotifier {
  RouteInfoDialogController({
    required List<PinDto> pins,
    required RouteInformationService routeInformationService,
    DateTime Function()? nowProvider,
  }) : _routeInformationService = routeInformationService,
       _nowProvider = nowProvider ?? DateTime.now {
    _pins.addAll(pins);
    _rebuildSegments();
    if (_pins.isNotEmpty) {
      _selectedPinId = _pins.first.pinId;
      if (_segments.isNotEmpty) {
        _selectedSegmentIndex = 0;
      }
    }
  }

  final RouteInformationService _routeInformationService;
  final DateTime Function() _nowProvider;

  final List<PinDto> _pins = [];
  final List<RouteInfoSegmentState> _segments = [];

  bool _isLoading = false;
  String? _errorMessage;
  int _latestRequestToken = 0;
  int? _selectedSegmentIndex;
  String? _selectedPinId;

  UnmodifiableListView<PinDto> get pins => UnmodifiableListView(_pins);
  UnmodifiableListView<RouteInfoSegmentState> get segments =>
      UnmodifiableListView(_segments);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get selectedSegmentIndex => _selectedSegmentIndex;
  String? get selectedPinId => _selectedPinId;
  RouteInfoSegmentState? get selectedSegment {
    if (_selectedSegmentIndex == null) {
      return null;
    }
    if (_selectedSegmentIndex! < 0 ||
        _selectedSegmentIndex! >= _segments.length) {
      return null;
    }
    return _segments[_selectedSegmentIndex!];
  }

  void reorderPins({required int oldIndex, required int newIndex}) {
    if (oldIndex < 0 || oldIndex >= _pins.length) {
      return;
    }
    var adjustedNewIndex = newIndex;
    if (adjustedNewIndex > oldIndex) {
      adjustedNewIndex -= 1;
    }
    if (adjustedNewIndex < 0 || adjustedNewIndex >= _pins.length) {
      return;
    }
    final pin = _pins.removeAt(oldIndex);
    _pins.insert(adjustedNewIndex, pin);
    _rebuildSegments();
    notifyListeners();
  }

  void updateTravelMode(int index, RouteTravelMode travelMode) {
    if (index < 0 || index >= _segments.length) {
      return;
    }
    if (_segments[index].travelMode == travelMode) {
      return;
    }
    _segments[index].travelMode = travelMode;
    notifyListeners();
  }

  void selectPin(String pinId) {
    _selectedPinId = pinId;
    final pinIndex = _pins.indexWhere((pin) => pin.pinId == pinId);
    if (pinIndex == -1) {
      _selectedSegmentIndex = null;
      notifyListeners();
      return;
    }

    if (_segments.isEmpty) {
      _selectedSegmentIndex = null;
    } else if (pinIndex == 0) {
      _selectedSegmentIndex = 0;
    } else if (pinIndex >= _segments.length) {
      _selectedSegmentIndex = _segments.length - 1;
    } else {
      _selectedSegmentIndex = pinIndex - 1;
    }
    notifyListeners();
  }

  void selectSegment(int index) {
    if (index < 0 || index >= _segments.length) {
      return;
    }
    _selectedSegmentIndex = index;
    _selectedPinId = _segments[index].to.pinId;
    notifyListeners();
  }

  Future<void> searchRoutes() async {
    if (_segments.isEmpty) {
      _errorMessage = '経路情報を表示するには2件以上の訪問場所が必要です。';
      notifyListeners();
      return;
    }

    final requestToken = ++_latestRequestToken;
    _isLoading = true;
    _errorMessage = null;

    for (final segment in _segments) {
      segment.candidate = null;
    }
    notifyListeners();

    var hasCandidate = false;

    try {
      for (var i = 0; i < _segments.length; i++) {
        final segment = _segments[i];
        final locations = [
          RouteLocation(
            id: segment.from.pinId,
            latitude: segment.from.latitude,
            longitude: segment.from.longitude,
            name: segment.from.locationName,
          ),
          RouteLocation(
            id: segment.to.pinId,
            latitude: segment.to.latitude,
            longitude: segment.to.longitude,
            name: segment.to.locationName,
          ),
        ];

        final departureTime = segment.from.visitStartDate ?? _nowProvider();

        final candidates = await _routeInformationService.fetchRoutes(
          locations: locations,
          travelMode: segment.travelMode,
          departureTime: departureTime,
        );

        if (!_shouldAcceptResponse(requestToken)) {
          return;
        }

        if (candidates.isNotEmpty) {
          segment.candidate = candidates.first;
          hasCandidate = true;
        } else {
          segment.candidate = null;
        }
        notifyListeners();
      }

      if (!hasCandidate) {
        _errorMessage = '経路情報を取得できませんでした。';
      }
    } catch (error, stackTrace) {
      logger.e(
        'RouteInfoDialogController.searchRoutes: ${error.toString()}',
        error: error,
        stackTrace: stackTrace,
      );
      if (!_shouldAcceptResponse(requestToken)) {
        return;
      }
      _errorMessage = '経路情報の取得中にエラーが発生しました。';
    } finally {
      if (_shouldAcceptResponse(requestToken)) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void _rebuildSegments() {
    _segments
      ..clear()
      ..addAll(
        List<RouteInfoSegmentState>.generate(
          _pins.length > 1 ? _pins.length - 1 : 0,
          (index) => RouteInfoSegmentState(
            from: _pins[index],
            to: _pins[index + 1],
            travelMode: RouteTravelMode.drive,
          ),
        ),
      );

    if (_segments.isEmpty) {
      _selectedSegmentIndex = null;
    } else if (_selectedSegmentIndex != null) {
      if (_selectedSegmentIndex! >= _segments.length) {
        _selectedSegmentIndex = _segments.length - 1;
      }
    } else {
      _selectedSegmentIndex = 0;
    }
    if (_selectedPinId != null &&
        !_pins.any((pin) => pin.pinId == _selectedPinId)) {
      _selectedPinId = _pins.isNotEmpty ? _pins.first.pinId : null;
    }
    _errorMessage = null;
  }

  bool _shouldAcceptResponse(int token) {
    return token == _latestRequestToken;
  }
}
