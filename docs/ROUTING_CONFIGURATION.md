# Edible Routing Configuration

Phase 26 removes routing endpoint configuration from UI/data-source code.

Configure with Flutter dart-defines.

Development defaults:
- ROUTING_BASE_URL=https://router.project-osrm.org
- ROUTING_PROFILE=foot
- no API key

Example production-shaped command:

flutter run \
  --dart-define=ROUTING_BASE_URL=https://your-routing-host.example \
  --dart-define=ROUTING_PROFILE=foot \
  --dart-define=ROUTING_API_KEY=YOUR_KEY \
  --dart-define=ROUTING_API_KEY_HEADER=Authorization \
  --dart-define="ROUTING_API_KEY_PREFIX=Bearer "

Release:

flutter build appbundle --release \
  --dart-define=ROUTING_BASE_URL=https://your-routing-host.example \
  --dart-define=ROUTING_PROFILE=foot \
  --dart-define=ROUTING_API_KEY=YOUR_KEY

Do not commit production API keys to source control.

Important:
This adapter expects an OSRM-compatible route endpoint:

/route/v1/{profile}/{lon,lat;lon,lat...}

If the final provider uses a different request/response contract, implement
another DayRouteRemoteDataSource/Repository adapter while keeping
DayRouteRepository unchanged.
