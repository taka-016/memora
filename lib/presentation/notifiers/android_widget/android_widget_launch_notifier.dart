import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/usecases/android_widget/watch_android_widget_launch_uri_usecase.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/trip/get_trip_entry_by_id_usecase.dart';
import 'package:memora/core/app_logger.dart';

sealed class AndroidWidgetLaunchResolution extends Equatable {
  const AndroidWidgetLaunchResolution({required this.memberId});

  final String memberId;
}

final class AndroidWidgetLaunchDestination
    extends AndroidWidgetLaunchResolution {
  const AndroidWidgetLaunchDestination({
    required super.memberId,
    required this.groupId,
    required this.year,
    required this.tripId,
    required this.groups,
  });

  final String groupId;
  final int year;
  final String tripId;
  final List<GroupDto> groups;

  @override
  List<Object?> get props => [memberId, groupId, year, tripId, groups];
}

final class AndroidWidgetSettingsLaunchDestination
    extends AndroidWidgetLaunchResolution {
  const AndroidWidgetSettingsLaunchDestination({required super.memberId});

  @override
  List<Object?> get props => [memberId];
}

final class AndroidWidgetLaunchFailure extends AndroidWidgetLaunchResolution {
  const AndroidWidgetLaunchFailure({required super.memberId});

  @override
  List<Object?> get props => [memberId];
}

class AndroidWidgetLaunchState extends Equatable {
  const AndroidWidgetLaunchState({
    this.pendingTripId,
    this.isSettingsLaunchPending = false,
    this.isInitialUriLoading = false,
    this.isResolving = false,
    this.resolution,
  });

  final String? pendingTripId;
  final bool isSettingsLaunchPending;
  final bool isInitialUriLoading;
  final bool isResolving;
  final AndroidWidgetLaunchResolution? resolution;

  @override
  List<Object?> get props => [
    pendingTripId,
    isSettingsLaunchPending,
    isInitialUriLoading,
    isResolving,
    resolution,
  ];

  AndroidWidgetLaunchState copyWith({
    String? pendingTripId,
    bool? isSettingsLaunchPending,
    bool? isInitialUriLoading,
    bool? isResolving,
    AndroidWidgetLaunchResolution? resolution,
    bool clearPendingTripId = false,
    bool clearSettingsLaunchPending = false,
    bool clearResolution = false,
  }) {
    return AndroidWidgetLaunchState(
      pendingTripId: clearPendingTripId
          ? null
          : (pendingTripId ?? this.pendingTripId),
      isSettingsLaunchPending: clearSettingsLaunchPending
          ? false
          : (isSettingsLaunchPending ?? this.isSettingsLaunchPending),
      isInitialUriLoading: isInitialUriLoading ?? this.isInitialUriLoading,
      isResolving: isResolving ?? this.isResolving,
      resolution: clearResolution ? null : (resolution ?? this.resolution),
    );
  }
}

final androidWidgetLaunchNotifierProvider =
    NotifierProvider<AndroidWidgetLaunchNotifier, AndroidWidgetLaunchState>(
      AndroidWidgetLaunchNotifier.new,
    );

class AndroidWidgetLaunchNotifier extends Notifier<AndroidWidgetLaunchState> {
  static const _launchScheme = 'memorawidget';
  static const _openTripHost = 'opentrip';
  static const _openSettingsHost = 'opensettings';
  static const _tripIdQueryParameter = 'tripId';

  StreamSubscription<Uri?>? _subscription;
  int _requestVersion = 0;
  ({String tripId, int requestVersion})? _resolvingRequest;
  String? _resolvedTripId;

  @override
  AndroidWidgetLaunchState build() {
    final usecase = ref.watch(watchAndroidWidgetLaunchUriUsecaseProvider);
    _subscription = usecase.clickedUris.listen(
      _receiveUri,
      onError: (Object error, StackTrace stackTrace) {
        logger.e(
          'AndroidWidgetLaunchNotifier.widgetClicked: ${error.toString()}',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
      _subscription = null;
    });
    unawaited(_loadInitialUri(usecase));
    return const AndroidWidgetLaunchState(isInitialUriLoading: true);
  }

  Future<void> _loadInitialUri(
    WatchAndroidWidgetLaunchUriUsecase usecase,
  ) async {
    final initialRequestVersion = _requestVersion;
    try {
      final uri = await usecase.getInitialUri();
      if (_requestVersion != initialRequestVersion) {
        state = state.copyWith(isInitialUriLoading: false);
        return;
      }
      if (_isSettingsLaunchUri(uri)) {
        _acceptSettingsLaunch(isInitialUriLoading: false);
        return;
      }
      final tripId = _extractTripId(uri);
      if (tripId == null) {
        state = state.copyWith(isInitialUriLoading: false);
        return;
      }
      _acceptTripId(tripId, isInitialUriLoading: false);
    } catch (e, stack) {
      logger.e(
        'AndroidWidgetLaunchNotifier.initialUri: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(isInitialUriLoading: false);
    }
  }

  void _receiveUri(Uri? uri) {
    if (_isSettingsLaunchUri(uri)) {
      if (state.isSettingsLaunchPending ||
          state.resolution is AndroidWidgetSettingsLaunchDestination) {
        return;
      }
      _acceptSettingsLaunch();
      return;
    }
    final tripId = _extractTripId(uri);
    final resolvingRequest = _resolvingRequest;
    if (tripId == null ||
        tripId == state.pendingTripId ||
        (tripId == resolvingRequest?.tripId &&
            resolvingRequest?.requestVersion == _requestVersion) ||
        tripId == _resolvedTripId) {
      return;
    }
    _acceptTripId(tripId);
  }

  void _acceptTripId(String tripId, {bool? isInitialUriLoading}) {
    _requestVersion++;
    _resolvedTripId = null;
    state = state.copyWith(
      pendingTripId: tripId,
      isSettingsLaunchPending: false,
      isInitialUriLoading: isInitialUriLoading,
      isResolving: false,
      clearResolution: true,
    );
  }

  void _acceptSettingsLaunch({bool? isInitialUriLoading}) {
    _requestVersion++;
    _resolvingRequest = null;
    _resolvedTripId = null;
    state = state.copyWith(
      isSettingsLaunchPending: true,
      isInitialUriLoading: isInitialUriLoading,
      isResolving: false,
      clearPendingTripId: true,
      clearResolution: true,
    );
  }

  Future<void> resolvePendingLaunch(MemberDto member) async {
    if (state.isSettingsLaunchPending) {
      state = state.copyWith(
        isResolving: false,
        clearSettingsLaunchPending: true,
        resolution: AndroidWidgetSettingsLaunchDestination(memberId: member.id),
      );
      return;
    }
    final tripId = state.pendingTripId;
    if (tripId == null) {
      return;
    }

    final requestVersion = _requestVersion;
    _resolvingRequest = (tripId: tripId, requestVersion: requestVersion);
    state = state.copyWith(
      isResolving: true,
      clearPendingTripId: true,
      clearResolution: true,
    );

    try {
      final trip = await ref
          .read(getTripEntryByIdUsecaseProvider)
          .execute(tripId);
      if (!_isCurrentRequest(requestVersion)) {
        return;
      }
      if (trip == null) {
        _completeResolution(
          requestVersion,
          tripId,
          AndroidWidgetLaunchFailure(memberId: member.id),
        );
        return;
      }

      final groups = await ref
          .read(getGroupsWithMembersUsecaseProvider)
          .execute(member);
      if (!_isCurrentRequest(requestVersion)) {
        return;
      }
      if (!groups.any((group) => group.id == trip.groupId)) {
        _completeResolution(
          requestVersion,
          tripId,
          AndroidWidgetLaunchFailure(memberId: member.id),
        );
        return;
      }

      _completeResolution(
        requestVersion,
        tripId,
        AndroidWidgetLaunchDestination(
          memberId: member.id,
          groupId: trip.groupId,
          year: trip.year,
          tripId: trip.id,
          groups: groups,
        ),
      );
    } catch (error, stackTrace) {
      logger.e(
        'AndroidWidgetLaunchNotifier.resolvePendingLaunch: ${error.toString()}',
        error: error,
        stackTrace: stackTrace,
      );
      if (_isCurrentRequest(requestVersion)) {
        _completeResolution(
          requestVersion,
          tripId,
          AndroidWidgetLaunchFailure(memberId: member.id),
        );
      }
    } finally {
      if (_resolvingRequest ==
              (tripId: tripId, requestVersion: requestVersion) &&
          !_isCurrentRequest(requestVersion)) {
        _resolvingRequest = null;
      }
    }
  }

  AndroidWidgetLaunchResolution? takeResolution(String memberId) {
    final resolution = state.resolution;
    if (resolution == null) {
      return null;
    }
    _resolvedTripId = null;
    state = state.copyWith(clearResolution: true);
    return resolution.memberId == memberId ? resolution : null;
  }

  void cancelPendingLaunch() {
    _requestVersion++;
    _resolvingRequest = null;
    _resolvedTripId = null;
    state = AndroidWidgetLaunchState(
      isInitialUriLoading: state.isInitialUriLoading,
    );
  }

  bool _isCurrentRequest(int requestVersion) {
    return requestVersion == _requestVersion;
  }

  void _completeResolution(
    int requestVersion,
    String tripId,
    AndroidWidgetLaunchResolution resolution,
  ) {
    if (!_isCurrentRequest(requestVersion)) {
      return;
    }
    _resolvingRequest = null;
    _resolvedTripId = tripId;
    state = state.copyWith(isResolving: false, resolution: resolution);
  }

  String? _extractTripId(Uri? uri) {
    if (uri == null ||
        uri.scheme.toLowerCase() != _launchScheme ||
        uri.host.toLowerCase() != _openTripHost) {
      return null;
    }
    final tripId = uri.queryParameters[_tripIdQueryParameter]?.trim();
    return tripId == null || tripId.isEmpty ? null : tripId;
  }

  bool _isSettingsLaunchUri(Uri? uri) {
    return uri != null &&
        uri.scheme.toLowerCase() == _launchScheme &&
        uri.host.toLowerCase() == _openSettingsHost;
  }
}
