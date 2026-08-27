/// Backend API configuration.
abstract final class ApiConfig {
  /// Hosted backend (Azure App Service), backed by Aiven MySQL. Default for
  /// all builds so the app works without a local backend running.
  static const String _azureBaseUrl =
      'https://sunilmedical-bxg0bheub8aqdjfk.southindia-01.azurewebsites.net/v1';

  /// The Android emulator reaches the host machine's `localhost` via the
  /// special alias `10.0.2.2` — a plain `localhost` here would resolve to the
  /// emulator itself, not the dev machine running the backend. Opt in with
  /// `--dart-define=API_BASE_URL=http://10.0.2.2:5260/v1` when developing
  /// against a local backend.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _azureBaseUrl,
  );
}
