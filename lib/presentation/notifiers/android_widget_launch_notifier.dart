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
  const AndroidWidgetLaunchResolution();
}

final class AndroidWidgetLaunchDestination
    extends AndroidWidgetLaunchResolution {
  const AndroidWidgetLaunchDestination({
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
  List<Object?> get props => [groupId, year, tripId, groups];
}

final class AndroidWidgetLaunchFailure extends AndroidWidgetLaunchResolution {
  const AndroidWidgetLaunchFailure();

  @override
  List<Object?> get props => [];
}

class AndroidWidgetLaunchState extends Equatable {
  const AndroidWidgetLaunchState({
    this.pendingTripId,
    this.isInitialUriLoading = false,
    this.isResolving = false,
    this.resolution,
  });

  final String? pendingTripId;
  final bool isInitialUriLoading;
  final bool isResolving;
  final AndroidWidgetLaunchResolution? resolution;

  @override
  List<Object?> get props => [
    pendingTripId,
    isInitialUriLoading,
    isResolving,
    resolution,
  ];

  AndroidWidgetLaunchState copyWith({
    String? pendingTripId,
    bool? isInitialUriLoading,
    bool? isResolving,
    AndroidWidgetLaunchResolution? resolution,
    bool clearPendingTripId = false,
    bool clearResolution = false,
  }) {
    return AndroidWidgetLaunchState(
      pendingTripId: clearPendingTripId
          ? null
          : (pendingTripId ?? this.pendingTripId),
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
  static const _tripIdQueryParameter = 'tripId';

  StreamSubscription<Uri?>? _subscription;
  int _requestVersion = 0;
  String? _resolvingTripId;
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
      final tripId = _extractTripId(await usecase.getInitialUri());
      if (_requestVersion != initialRequestVersion) {
        state = state.copyWith(isInitialUriLoading: false);
        return;
      }
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
    final tripId = _extractTripId(uri);
    if (tripId == null ||
        tripId == state.pendingTripId ||
        tripId == _resolvingTripId ||
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
      isInitialUriLoading: isInitialUriLoading,
      isResolving: false,
      clearResolution: true,
    );
  }

  String? takePendingTripId() {
    final tripId = state.pendingTripId;
    if (tripId == null) {
      return null;
    }
    state = state.copyWith(clearPendingTripId: true);
    return tripId;
  }

  Future<void> resolvePendingLaunch(MemberDto member) async {
    final tripId = state.pendingTripId;
    if (tripId == null) {
      return;
    }

    final requestVersion = _requestVersion;
    _resolvingTripId = tripId;
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
          const AndroidWidgetLaunchFailure(),
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
          const AndroidWidgetLaunchFailure(),
        );
        return;
      }

      _completeResolution(
        requestVersion,
        tripId,
        AndroidWidgetLaunchDestination(
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
          const AndroidWidgetLaunchFailure(),
        );
      }
    } finally {
      if (_resolvingTripId == tripId && !_isCurrentRequest(requestVersion)) {
        _resolvingTripId = null;
      }
    }
  }

  AndroidWidgetLaunchResolution? takeResolution() {
    final resolution = state.resolution;
    if (resolution == null) {
      return null;
    }
    _resolvedTripId = null;
    state = state.copyWith(clearResolution: true);
    return resolution;
  }

  void cancelPendingLaunch() {
    _requestVersion++;
    _resolvingTripId = null;
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
    _resolvingTripId = null;
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
}
