class RoutingConfig {
  const RoutingConfig._();

  static const baseUrl = String.fromEnvironment(
    'ROUTING_BASE_URL',
    defaultValue: 'https://router.project-osrm.org',
  );

  static const profile = String.fromEnvironment(
    'ROUTING_PROFILE',
    defaultValue: 'foot',
  );

  static const apiKey = String.fromEnvironment(
    'ROUTING_API_KEY',
    defaultValue: '',
  );

  static const apiKeyHeader = String.fromEnvironment(
    'ROUTING_API_KEY_HEADER',
    defaultValue: 'Authorization',
  );

  static const apiKeyPrefix = String.fromEnvironment(
    'ROUTING_API_KEY_PREFIX',
    defaultValue: 'Bearer ',
  );

  static const userAgent = String.fromEnvironment(
    'ROUTING_USER_AGENT',
    defaultValue: 'Edible travel app route preview',
  );

  static bool get hasApiKey => apiKey.trim().isNotEmpty;
}
