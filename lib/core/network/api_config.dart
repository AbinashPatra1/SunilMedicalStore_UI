/// Backend API configuration.
abstract final class ApiConfig {
  /// The Android emulator reaches the host machine's `localhost` via the
  /// special alias `10.0.2.2` — a plain `localhost` here would resolve to the
  /// emulator itself, not the dev machine running the backend.
  static const String _localDevBaseUrl = 'http://10.0.2.2:5260/v1';

  /// Base URL for all API calls, including the `/v1` prefix.
  ///
  /// Override at build time with `--dart-define=API_BASE_URL=https://...`
  /// once a hosted (Azure) URL exists.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _localDevBaseUrl,
  );
}
