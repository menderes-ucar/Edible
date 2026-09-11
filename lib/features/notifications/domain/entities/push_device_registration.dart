class PushDeviceRegistration {
  const PushDeviceRegistration({
    required this.token,
    required this.platform,
    required this.deviceId,
    required this.locale,
    required this.timezone,
  });

  final String token;
  final String platform;
  final String deviceId;
  final String locale;
  final String timezone;

  Map<String, dynamic> toMap() => {
        'token': token.trim(),
        'platform': platform.trim().toLowerCase(),
        'device_id': deviceId.trim(),
        'locale': locale.trim(),
        'timezone': timezone.trim().isEmpty ? 'UTC' : timezone.trim(),
      };
}
