import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/services/firestore_read_probe.dart';

extension MeasuredQuery<T extends Object?> on Query<T> {
  Future<QuerySnapshot<T>> measuredGet(
    String site, {
    GetOptions? options,
    required String target,
  }) async {
    final probe = FirestoreReadProbe.current;
    if (probe == null) return get(options);
    if (target.isEmpty) throw StateError('Queryの取得先が未指定です: $site');
    final read = probe.start(site: site, target: target, kind: 'get');
    try {
      final result = await get(options);
      read.receive(
        documents: result.docs.length,
        changes: 0,
        fromCache: result.metadata.isFromCache,
        pendingWrites: result.metadata.hasPendingWrites,
      );
      read.end();
      return result;
    } catch (error) {
      read.fail(error.toString());
      rethrow;
    }
  }

  Stream<QuerySnapshot<T>> measuredSnapshots(
    String site, {
    required String target,
  }) {
    final probe = FirestoreReadProbe.current;
    if (probe == null) return snapshots();
    if (target.isEmpty) throw StateError('Queryの取得先が未指定です: $site');
    return _observeStream(
      snapshots,
      () => probe.start(site: site, target: target, kind: 'subscribe'),
      (read, result) => read.receive(
        documents: result.docs.length,
        changes: result.docChanges.length,
        fromCache: result.metadata.isFromCache,
        pendingWrites: result.metadata.hasPendingWrites,
      ),
    );
  }
}

extension MeasuredDocument<T extends Object?> on DocumentReference<T> {
  Future<DocumentSnapshot<T>> measuredGet(
    String site, [
    GetOptions? options,
  ]) async {
    final probe = FirestoreReadProbe.current;
    if (probe == null) return get(options);
    final read = probe.start(site: site, target: path, kind: 'get');
    try {
      final result = await get(options);
      read.receive(
        documents: result.exists ? 1 : 0,
        changes: 0,
        fromCache: result.metadata.isFromCache,
        pendingWrites: result.metadata.hasPendingWrites,
      );
      read.end();
      return result;
    } catch (error) {
      read.fail(error.toString());
      rethrow;
    }
  }

  Stream<DocumentSnapshot<T>> measuredSnapshots(String site) {
    final probe = FirestoreReadProbe.current;
    if (probe == null) return snapshots();
    return _observeStream(
      snapshots,
      () => probe.start(site: site, target: path, kind: 'subscribe'),
      (read, result) => read.receive(
        documents: result.exists ? 1 : 0,
        changes: result.exists ? 1 : 0,
        fromCache: result.metadata.isFromCache,
        pendingWrites: result.metadata.hasPendingWrites,
      ),
    );
  }
}

extension MeasuredTransaction on Transaction {
  Future<DocumentSnapshot<T>> measuredGet<T extends Object?>(
    String site,
    DocumentReference<T> reference,
  ) async {
    final probe = FirestoreReadProbe.current;
    if (probe == null) return get(reference);
    final read = probe.start(
      site: site,
      target: reference.path,
      kind: 'transaction',
    );
    try {
      final result = await get(reference);
      read.receive(
        documents: result.exists ? 1 : 0,
        changes: 0,
        fromCache: result.metadata.isFromCache,
        pendingWrites: result.metadata.hasPendingWrites,
      );
      read.end();
      return result;
    } catch (error) {
      read.fail(error.toString());
      rethrow;
    }
  }
}

Stream<T> _observeStream<T>(
  Stream<T> Function() source,
  FirestoreReadObservation Function() start,
  void Function(FirestoreReadObservation, T) receive,
) {
  late StreamController<T> controller;
  StreamSubscription<T>? subscription;
  FirestoreReadObservation? read;
  controller = StreamController<T>(
    onListen: () {
      final observation = read = start();
      try {
        subscription = source().listen(
          (value) {
            receive(observation, value);
            controller.add(value);
          },
          onError: (Object error, StackTrace stack) {
            observation.fail(error.toString());
            controller.addError(error, stack);
          },
          onDone: controller.close,
        );
      } catch (error, stack) {
        observation.fail(error.toString());
        controller.addError(error, stack);
        unawaited(controller.close());
      }
    },
    onPause: () => subscription?.pause(),
    onResume: () => subscription?.resume(),
    onCancel: () async {
      await subscription?.cancel();
      read?.end();
    },
  );
  return controller.stream;
}
