import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';

enum SuggestionResult { ok, invalid, duplicate, rateLimited, failed }

enum ReportIssueResult { ok, invalid, rateLimited, failed }

enum ReportReason {
  wrongInfo('wrong_info'),
  closed('closed'),
  ownerRequest('owner_request'),
  inappropriate('inappropriate'),
  other('other');

  const ReportReason(this.code);
  final String code;
}

/// Calls the place-suggestion and listing-report RPCs. Validation, rate limits
/// and moderation rules live on the server (migration 20261017000001).
class SuggestionsService {
  const SuggestionsService();

  SupabaseClient get _client {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase is not ready.');
    return client;
  }

  Future<SuggestionResult> submit({
    required String name,
    required String city,
    required String country,
    required String category,
    String? note,
    String? website,
  }) async {
    try {
      final status = await _client.rpc('submit_place_suggestion', params: {
        'p_name': name,
        'p_city': city,
        'p_country': country,
        'p_category': category,
        'p_note': note,
        'p_website': website,
      });
      return switch (status?.toString()) {
        'ok' => SuggestionResult.ok,
        'invalid' => SuggestionResult.invalid,
        'duplicate' => SuggestionResult.duplicate,
        'rate_limited' => SuggestionResult.rateLimited,
        _ => SuggestionResult.failed,
      };
    } catch (_) {
      return SuggestionResult.failed;
    }
  }

  Future<ReportIssueResult> reportIssue({
    required String contentId,
    required String contentTitle,
    required ReportReason reason,
    String? details,
  }) async {
    try {
      final status = await _client.rpc('report_content_issue', params: {
        'p_content_id': contentId,
        'p_content_title': contentTitle,
        'p_reason': reason.code,
        'p_details': details,
      });
      return switch (status?.toString()) {
        'ok' => ReportIssueResult.ok,
        'invalid' => ReportIssueResult.invalid,
        'rate_limited' => ReportIssueResult.rateLimited,
        _ => ReportIssueResult.failed,
      };
    } catch (_) {
      return ReportIssueResult.failed;
    }
  }
}
