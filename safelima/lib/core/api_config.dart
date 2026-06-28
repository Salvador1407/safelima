class ApiConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://safelima-backend-788519438030.us-central1.run.app',
  );

  static String endpoint(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$apiBaseUrl$normalizedPath';
  }
}
