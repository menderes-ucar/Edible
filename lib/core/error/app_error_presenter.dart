import 'package:flutter/widgets.dart';

import '../localization/app_localizations.dart';

class AppErrorPresenter {
  AppErrorPresenter._();

  static String message(
    BuildContext context, [
    Object? error,
  ]) {
    final normalized = (error?.toString() ?? '').trim().toLowerCase();
    if (normalized.contains('invalid_trip_date_range')) {
      return context.l10n.text('vacationDateRangeInvalid').replaceAll(
            '{count}',
            '30',
          );
    }

    if (_containsAny(normalized, const [
      'invalid login credentials',
      'invalid credentials',
      'wrong password',
    ])) {
      return context.l10n.text('invalidCredentials');
    }

    if (_containsAny(normalized, const [
      'email not confirmed',
      'email_not_confirmed',
    ])) {
      return context.l10n.text('emailNotConfirmed');
    }

    if (_containsAny(normalized, const [
      'user already registered',
      'already registered',
      'email already',
    ])) {
      return context.l10n.text('emailAlreadyRegistered');
    }

    if (normalized.contains('saved_trip_operation_in_progress')) {
      return context.l10n.text('tripOperationInProgress');
    }
    if (normalized.contains('itinerary_day_capacity_exceeded')) {
      return context.l10n.text('itineraryDayCapacityExceeded');
    }
    if (normalized.contains('itinerary_time_limit_reached')) {
      return context.l10n.text('itineraryTimeLimitReached');
    }

    if (_containsAny(normalized, const [
      'socketexception',
      'network',
      'connection',
      'timeout',
      'timed out',
      'failed host lookup',
    ])) {
      return context.l10n.text('networkError');
    }

    return context.l10n.text('somethingWentWrong');
  }

  static bool _containsAny(String source, List<String> needles) {
    if (source.isEmpty) return false;
    return needles.any(source.contains);
  }
}
