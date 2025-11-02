import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/domain/services/route_information_service.dart';
import 'package:memora/domain/value_objects/route/route_candidate.dart';
import 'package:memora/domain/value_objects/route/route_leg.dart';
import 'package:memora/domain/value_objects/route/route_location.dart';
import 'package:memora/domain/value_objects/route/route_travel_mode.dart';
import 'package:memora/env/env.dart';
import 'package:memora/infrastructure/services/google_routes_api_route_information_service.dart';

class RouteInfoDialog extends StatefulWidget {
  final List<PinDto> pins;
  final RouteInformationService? routeInformationService;

  const RouteInfoDialog({
    super.key,
    required this.pins,
    this.routeInformationService,
  });

  @override
  State<RouteInfoDialog> createState() => _RouteInfoDialogState();
}

class _RouteInfoDialogState extends State<RouteInfoDialog> {
  late final RouteInformationService _routeInformationService;
  late final List<PinDto> _sortedPins;
  bool _isLoading = true;
  String? _errorMessage;
  RouteTravelMode _selectedTravelMode = RouteTravelMode.drive;
  List<RouteCandidate> _candidates = const [];
  int _currentTabIndex = 0;
  int _latestFetchToken = 0;

  bool get _hasSufficientPins => _sortedPins.length >= 2;

  @override
  void initState() {
    super.initState();
    _routeInformationService =
        widget.routeInformationService ??
        GoogleRoutesApiRouteInformationService(apiKey: Env.googlePlacesApiKey);
    _sortedPins = _sortPins(widget.pins);
    _fetchRoutes();
  }

  List<PinDto> _sortPins(List<PinDto> pins) {
    final indexed = pins.asMap().entries.map((entry) {
      final index = entry.key;
      final pin = entry.value;
      return (
        index: index,
        pin: pin,
        sortKey: pin.visitStartDate ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    }).toList();

    indexed.sort((a, b) {
      final dateCompare = a.sortKey.compareTo(b.sortKey);
      if (dateCompare != 0) {
        return dateCompare;
      }
      return a.index.compareTo(b.index);
    });

    return indexed.map((e) => e.pin).toList();
  }

  Future<void> _fetchRoutes() async {
    final fetchToken = ++_latestFetchToken;
    final requestedTravelMode = _selectedTravelMode;

    if (!_hasSufficientPins) {
      setState(() {
        _isLoading = false;
        _errorMessage = '経路情報を表示するには2件以上の訪問場所が必要です。';
        _candidates = const [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final locations = _sortedPins
          .map(
            (pin) => RouteLocation(
              id: pin.pinId,
              latitude: pin.latitude,
              longitude: pin.longitude,
              name: pin.locationName,
            ),
          )
          .toList();

      final candidates = await _routeInformationService.fetchRoutes(
        locations: locations,
        travelMode: _selectedTravelMode,
      );

      if (_shouldIgnoreResponse(fetchToken, requestedTravelMode)) {
        return;
      }

      setState(() {
        _candidates = candidates;
        _isLoading = false;
        _currentTabIndex = 0;
        if (_candidates.isEmpty) {
          _errorMessage = '経路情報を取得できませんでした。';
        }
      });
    } catch (e, stack) {
      logger.e(
        '_RouteInfoDialogState._fetchRoutes: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      if (_shouldIgnoreResponse(fetchToken, requestedTravelMode)) {
        return;
      }
      setState(() {
        _isLoading = false;
        _candidates = const [];
        _errorMessage = '経路情報の取得に失敗しました: $e';
      });
    }
  }

  bool _shouldIgnoreResponse(int token, RouteTravelMode requestedMode) {
    if (!mounted) {
      return true;
    }
    if (token != _latestFetchToken) {
      return true;
    }
    if (_selectedTravelMode != requestedMode) {
      return true;
    }
    return false;
  }

  void _onTravelModeSelected(RouteTravelMode mode) {
    if (_selectedTravelMode == mode) {
      return;
    }
    setState(() {
      _selectedTravelMode = mode;
    });
    _fetchRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              _buildTravelModeSelector(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Text(
          '経路情報',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildTravelModeSelector() {
    final modes = RouteTravelMode.values;
    final theme = Theme.of(context);
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: modes.map((mode) {
        final isSelected = _selectedTravelMode == mode;
        final icon = _iconForTravelMode(mode);
        final foregroundColor = isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant;
        final backgroundColor = isSelected
            ? theme.colorScheme.primary.withAlpha((0.12 * 255).round())
            : Colors.transparent;
        final borderColor = isSelected
            ? theme.colorScheme.primary
            : theme.dividerColor.withAlpha((0.6 * 255).round());

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: IconButton(
                tooltip: mode.label,
                onPressed: () => _onTravelModeSelected(mode),
                icon: Icon(icon, color: foregroundColor),
                splashRadius: 28,
              ),
            ),
            const SizedBox(height: 6),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, textAlign: TextAlign.center));
    }

    if (_candidates.isEmpty) {
      return const Center(child: Text('経路情報が見つかりませんでした。'));
    }

    return DefaultTabController(
      length: _candidates.length,
      initialIndex: _currentTabIndex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            isScrollable: true,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: List.generate(
              _candidates.length,
              (index) => Tab(text: '候補${index + 1}'),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: _candidates
                  .map((candidate) => _buildCandidateView(candidate))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateView(RouteCandidate candidate) {
    final pairCount = math.min(candidate.legs.length, _sortedPins.length - 1);
    final legs = candidate.legs.take(pairCount).toList();

    return ListView(
      children: [
        _buildCandidateSummary(candidate),
        const SizedBox(height: 16),
        ...List.generate(legs.length, (index) {
          final leg = legs[index];
          final fromPin = _sortedPins[index];
          final toPin = _sortedPins[index + 1];
          return Padding(
            padding: EdgeInsets.only(bottom: index == legs.length - 1 ? 0 : 12),
            child: _buildLegRow(leg, fromPin, toPin),
          );
        }),
        if (candidate.warnings.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildCandidateWarnings(candidate.warnings),
        ],
      ],
    );
  }

  Widget _buildCandidateSummary(RouteCandidate candidate) {
    final distance = candidate.localizedDistanceText ?? '-';
    final duration = candidate.localizedDurationText ?? '-';
    final description = candidate.description?.isNotEmpty == true
        ? candidate.description!
        : '候補情報なし';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text('合計所要時間: $duration'),
        Text('合計距離: $distance'),
      ],
    );
  }

  Widget _buildLegRow(RouteLeg leg, PinDto fromPin, PinDto toPin) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(Icons.arrow_downward, size: 24, color: Colors.blueGrey),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_formatPinName(fromPin)} → ${_formatPinName(toPin)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text('所要時間: ${leg.localizedDurationText ?? '-'}'),
              Text('距離: ${leg.localizedDistanceText ?? '-'}'),
              Text('経路概要: ${leg.primaryInstruction ?? '-'}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCandidateWarnings(List<String> warnings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('追加の注意事項', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...warnings.map(
            (warning) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(warning),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPinName(PinDto pin) {
    if (pin.locationName != null && pin.locationName!.isNotEmpty) {
      return pin.locationName!;
    }
    return pin.pinId;
  }

  IconData _iconForTravelMode(RouteTravelMode mode) {
    switch (mode) {
      case RouteTravelMode.drive:
        return Icons.directions_car;
      case RouteTravelMode.walk:
        return Icons.directions_walk;
      case RouteTravelMode.transit:
        return Icons.directions_transit;
    }
  }
}
