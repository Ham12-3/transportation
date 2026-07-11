/// All secrets & endpoints come from --dart-define at build time.
///
/// Example:
///   flutter run \
///     --dart-define=TFL_APP_KEY=xxxxx \
///     --dart-define=OPENSKY_USER=you --dart-define=OPENSKY_PASS=secret
class ApiConfig {
  ApiConfig._();

  // Transport for London Unified API
  static const String tflBaseUrl = 'https://api.tfl.gov.uk';
  static const String tflAppKey = String.fromEnvironment('TFL_APP_KEY');
  static const String tflAppId = String.fromEnvironment('TFL_APP_ID');

  /// Query params appended to every TfL call. TfL works key-less at a low rate
  /// limit, so the app still runs with no key configured (great for demos).
  static Map<String, dynamic> get tflAuth => {
        if (tflAppKey.isNotEmpty) 'app_key': tflAppKey,
        if (tflAppId.isNotEmpty) 'app_id': tflAppId,
      };

  // Air fleet (OpenSky Network). Anonymous access is allowed but rate-limited;
  // supply credentials for a higher quota.
  static const String openSkyBaseUrl = 'https://opensky-network.org/api';
  static const String openSkyUser = String.fromEnvironment('OPENSKY_USER');
  static const String openSkyPass = String.fromEnvironment('OPENSKY_PASS');

  /// Optional override for a bespoke air-fleet endpoint. When set, the
  /// [AirFleetService] can be pointed at a provided feed instead of OpenSky.
  static const String airFleetBaseUrl =
      String.fromEnvironment('AIR_FLEET_URL', defaultValue: '');
  static const String airFleetKey = String.fromEnvironment('AIR_FLEET_KEY');
}
