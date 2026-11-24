class RoutingConfig {
  const RoutingConfig._();

  /// Default: the FOSSGIS pedestrian OSRM instance. The public OSRM demo
  /// server (router.project-osrm.org) only serves car profiles regardless of
  /// the profile in the URL, which produced driving routes labelled "walking".
  /// For heavy production traffic set ROUTING_BASE_URL to your own OSRM /
  /// OpenRouteService / GraphHopper endpoint (see ROUTING_API_KEY).
  static const baseUrl = String.fromEnvironment(
    'ROUTING_BASE_URL',
    defaultValue: 'https://routing.openstreetmap.de/routed-foot',
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

  /// True when routing runs on a dedicated provider (API key configured or a
  /// non-demo endpoint). Only the car-only OSRM demo is flagged as development.
  static bool get isProductionProvider =>
      hasApiKey || !baseUrl.contains('router.project-osrm.org');
}
