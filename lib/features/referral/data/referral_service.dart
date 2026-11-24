import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';

class ReferralInfo {
  const ReferralInfo({
    required this.code,
    required this.credits,
    required this.referrals,
  });

  final String code;
  final int credits;
  final int referrals;
}

class AssistantAccess {
  const AssistantAccess({required this.premium, required this.credits});

  final bool premium;
  final int credits;
}

enum RedeemResult { ok, invalidCode, ownCode, alreadyRedeemed, limitReached, failed }

/// Talks to the referral / free-AI-credit RPCs. All rules live on the server
/// (see migration 20261015000001); this class only calls them.
class ReferralService {
  const ReferralService();

  SupabaseClient get _client {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase is not ready.');
    return client;
  }

  Map<String, dynamic> _firstRow(Object? data) {
    if (data is List && data.isNotEmpty && data.first is Map) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Unexpected RPC response.');
  }

  int _int(Object? value) => value is num ? value.toInt() : 0;

  Future<ReferralInfo> getInfo() async {
    final row = _firstRow(await _client.rpc('get_my_referral_info'));
    final code = row['code']?.toString() ?? '';
    if (code.isEmpty) throw const FormatException('Missing referral code.');
    return ReferralInfo(
      code: code,
      credits: _int(row['credits']),
      referrals: _int(row['referrals']),
    );
  }

  Future<AssistantAccess> getAssistantAccess() async {
    final row = _firstRow(await _client.rpc('get_my_assistant_access'));
    return AssistantAccess(
      premium: row['premium'] == true,
      credits: _int(row['credits']),
    );
  }

  Future<RedeemResult> redeem(String code) async {
    try {
      final status = await _client.rpc(
        'redeem_referral_code',
        params: {'p_code': code},
      );
      return switch (status?.toString()) {
        'ok' => RedeemResult.ok,
        'invalid_code' => RedeemResult.invalidCode,
        'own_code' => RedeemResult.ownCode,
        'already_redeemed' => RedeemResult.alreadyRedeemed,
        'limit_reached' => RedeemResult.limitReached,
        _ => RedeemResult.failed,
      };
    } catch (_) {
      return RedeemResult.failed;
    }
  }
}
