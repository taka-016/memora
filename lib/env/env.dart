import 'package:envied/envied.dart';
part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'GOOGLE_PLACES_APIKEY', obfuscate: true)
  static String googlePlacesApiKey = _Env.googlePlacesApiKey;
}
