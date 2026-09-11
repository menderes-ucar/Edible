import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/subscription_entitlement.dart';

class SubscriptionRemoteDataSource {
  Future<SubscriptionEntitlement> getCurrentEntitlement() async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;

    if (client == null || user == null) {
      return SubscriptionEntitlement.free;
    }

    final row = await client
        .from('user_subscriptions')
        .select('plan, status, expires_at')
        .eq('user_id', user.id)
        .maybeSingle();

    if (row == null) {
      return SubscriptionEntitlement.free;
    }

    final map = Map<String, dynamic>.from(row as Map);
    final status = (map['status'] ?? '').toString().trim().toLowerCase();
    final expiresAt = DateTime.tryParse(
      map['expires_at']?.toString() ?? '',
    );

    final isCurrentlyEntitled = switch (status) {
      'active' || 'trialing' => true,
      // A cancelled subscription can remain entitled until its paid-through
      // expiry. This handles both common spellings without granting access
      // after expiry because SubscriptionEntitlement.isPremium checks time.
      'canceled' || 'cancelled' => expiresAt?.isAfter(DateTime.now()) == true,
      _ => false,
    };

    return SubscriptionEntitlement(
      plan: SubscriptionPlan.fromValue(map['plan']?.toString()),
      isActive: isCurrentlyEntitled,
      expiresAt: expiresAt,
    );
  }
}
