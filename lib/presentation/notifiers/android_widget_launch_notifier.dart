import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/usecases/android_widget/watch_android_widget_launch_uri_usecase.dart';
import 'package:memora/core/app_logger.dart';

class AndroidWidgetLaunchState extends Equatable {
  const AndroidWidgetLaunchState({this.pendingTripId});

  final String? pendingTripId;

  @override
  List<Object?> get props => [pendingTripId];
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
    return const AndroidWidgetLaunchState();
  }

  Future<void> _loadInitialUri(
    WatchAndroidWidgetLaunchUriUsecase usecase,
  ) async {
    try {
      _receiveUri(await usecase.getInitialUri());
    } catch (e, stack) {
      logger.e(
        'AndroidWidgetLaunchNotifier.initialUri: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
    }
  }

  void _receiveUri(Uri? uri) {
    final tripId = _extractTripId(uri);
    if (tripId == null) {
      return;
    }
    state = AndroidWidgetLaunchState(pendingTripId: tripId);
  }

  String? takePendingTripId() {
    final tripId = state.pendingTripId;
    if (tripId == null) {
      return null;
    }
    state = const AndroidWidgetLaunchState();
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
