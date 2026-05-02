import 'dart:async';

import 'package:http/http.dart' as http;

class GoogleApiKeyClient extends http.BaseClient {
  GoogleApiKeyClient({required this.apiKey, http.Client? inner})
    : _inner = inner ?? http.Client();

  final String apiKey;
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request is http.Request) {
      final updatedRequest =
          http.Request(request.method, _uriWithApiKey(request.url))
            ..bodyBytes = request.bodyBytes
            ..followRedirects = request.followRedirects
            ..headers.addAll(request.headers)
            ..maxRedirects = request.maxRedirects
            ..persistentConnection = request.persistentConnection;
      return _inner.send(updatedRequest);
    }

    final updatedRequest =
        http.StreamedRequest(request.method, _uriWithApiKey(request.url))
          ..contentLength = request.contentLength
          ..followRedirects = request.followRedirects
          ..headers.addAll(request.headers)
          ..maxRedirects = request.maxRedirects
          ..persistentConnection = request.persistentConnection;

    unawaited(
      request.finalize().pipe(updatedRequest.sink).catchError((Object error) {
        updatedRequest.sink.addError(error);
      }),
    );
    return _inner.send(updatedRequest);
  }

  Uri _uriWithApiKey(Uri uri) {
    return uri.replace(
      queryParameters: {...uri.queryParameters, 'key': apiKey},
    );
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
