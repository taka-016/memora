abstract interface class AndroidWidgetLaunchUriSource {
  Future<Uri?> getInitialUri();

  Stream<Uri?> get clickedUris;
}
