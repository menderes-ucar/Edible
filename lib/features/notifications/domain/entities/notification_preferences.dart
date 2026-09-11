class NotificationPreferences {
  const NotificationPreferences({
    this.tripReminders = true,
    this.discoveryAlerts = true,
    this.memoryThrowbacks = true,
    this.achievementAlerts = true,
    this.socialAlerts = true,
    this.marketing = false,
    this.quietHoursEnabled = false,
    this.quietStartMinutes = 1320,
    this.quietEndMinutes = 480,
    this.timezone = 'UTC',
  });

  final bool tripReminders;
  final bool discoveryAlerts;
  final bool memoryThrowbacks;
  final bool achievementAlerts;
  final bool socialAlerts;
  final bool marketing;
  final bool quietHoursEnabled;
  final int quietStartMinutes;
  final int quietEndMinutes;
  final String timezone;

  NotificationPreferences copyWith({
    bool? tripReminders,
    bool? discoveryAlerts,
    bool? memoryThrowbacks,
    bool? achievementAlerts,
    bool? socialAlerts,
    bool? marketing,
    bool? quietHoursEnabled,
    int? quietStartMinutes,
    int? quietEndMinutes,
    String? timezone,
  }) {
    return NotificationPreferences(
      tripReminders: tripReminders ?? this.tripReminders,
      discoveryAlerts: discoveryAlerts ?? this.discoveryAlerts,
      memoryThrowbacks: memoryThrowbacks ?? this.memoryThrowbacks,
      achievementAlerts: achievementAlerts ?? this.achievementAlerts,
      socialAlerts: socialAlerts ?? this.socialAlerts,
      marketing: marketing ?? this.marketing,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStartMinutes: quietStartMinutes ?? this.quietStartMinutes,
      quietEndMinutes: quietEndMinutes ?? this.quietEndMinutes,
      timezone: timezone ?? this.timezone,
    );
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      tripReminders: map['trip_reminders'] != false,
      discoveryAlerts: map['discovery_alerts'] != false,
      memoryThrowbacks: map['memory_throwbacks'] != false,
      achievementAlerts: map['achievement_alerts'] != false,
      socialAlerts: map['social_alerts'] != false,
      marketing: map['marketing'] == true,
      quietHoursEnabled: map['quiet_hours_enabled'] == true,
      quietStartMinutes: _minutes(map['quiet_start_minutes'], 1320),
      quietEndMinutes: _minutes(map['quiet_end_minutes'], 480),
      timezone: (map['timezone'] ?? 'UTC').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'trip_reminders': tripReminders,
        'discovery_alerts': discoveryAlerts,
        'memory_throwbacks': memoryThrowbacks,
        'achievement_alerts': achievementAlerts,
        'social_alerts': socialAlerts,
        'marketing': marketing,
        'quiet_hours_enabled': quietHoursEnabled,
        'quiet_start_minutes': quietStartMinutes.clamp(0, 1439),
        'quiet_end_minutes': quietEndMinutes.clamp(0, 1439),
        'timezone': timezone.trim().isEmpty ? 'UTC' : timezone.trim(),
      };

  static int _minutes(dynamic value, int fallback) {
    final parsed = value is num ? value.toInt() : int.tryParse('$value');
    return (parsed ?? fallback).clamp(0, 1439);
  }
}
