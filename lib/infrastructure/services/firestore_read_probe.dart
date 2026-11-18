class FirestoreReadProbe {
  FirestoreReadProbe({
    required this.runId,
    required this.operationId,
    required this.emit,
    String? isolateId,
  }) : isolateId =
           isolateId ?? DateTime.now().microsecondsSinceEpoch.toString();

  static FirestoreReadProbe? current;
  final String runId;
  final String isolateId;
  final String Function() operationId;
  final void Function(Map<String, Object?>) emit;
  int _sequence = 0;

  FirestoreReadObservation start({
    required String site,
    required String target,
    required String kind,
  }) {
    final observation = FirestoreReadObservation._(emit, {
      'runId': runId,
      'isolateId': isolateId,
      'operationId': operationId(),
      'readId': '$isolateId:${++_sequence}',
      'site': site,
      'target': target,
      'kind': kind,
    });
    observation._send({'phase': 'start'});
    return observation;
  }
}

class FirestoreReadObservation {
  FirestoreReadObservation._(this._emit, this._identity);
  final void Function(Map<String, Object?>) _emit;
  final Map<String, Object?> _identity;
  final _origins = <String>{};

  void _send(Map<String, Object?> event) => _emit({..._identity, ...event});

  void receive({
    required int documents,
    required int changes,
    required bool fromCache,
    required bool pendingWrites,
  }) {
    final origin = pendingWrites ? 'local' : (fromCache ? 'cache' : 'server');
    _send({
      'phase': _origins.add(origin) ? 'initial' : 'changes',
      'origin': origin,
      'documents': documents,
      'changes': changes,
    });
  }

  void fail(String message) => _send({'phase': 'error', 'error': message});
  void end() => _send({'phase': 'end'});
}
