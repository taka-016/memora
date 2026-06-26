import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/usecases/android_widget/watch_android_widget_launch_uri_usecase.dart';
import 'package:memora/core/app_logger.dart';

class AndroidWidgetLaunchState extends Equatable {
  const AndroidWidgetLaunchState({
    this.pendingTripId,
    this.isInitialUriLoading = false,
  });

  final String? pendingTripId;
  final bool isInitialUriLoading;

  @override
  List<Object?> get props => [pendingTripId, isInitialUriLoading];

  AndroidWidgetLaunchState copyWith({
    String? pendingTripId,
    bool? isInitialUriLoading,
    bool clearPendingTripId = false,
  }) {
    return AndroidWidgetLaunchState(
      pendingTripId: clearPendingTripId
          ? null
          : (pendingTripId ?? this.pendingTripId),
      isInitialUriLoading: isInitialUriLoading ?? this.isInitialUriLoading,
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
    try {
      final tripId = _extractTripId(await usecase.getInitialUri());
      state = state.copyWith(pendingTripId: tripId, isInitialUriLoading: false);
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
    if (tripId == null) {
      return;
    }
    state = state.copyWith(pendingTripId: tripId);
  }

  String? takePendingTripId() {
    final tripId = state.pendingTripId;
    if (tripId == null) {
      return null;
    }
    state = state.copyWith(clearPendingTripId: true);
    return tripId;
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
