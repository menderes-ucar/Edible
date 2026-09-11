import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../notifications/data/notification_service.dart';

class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.isBlocked,
  });

  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isBlocked;

  factory ConversationSummary.fromMap(Map<String, dynamic> m) => ConversationSummary(
        id: m['conversation_id'].toString(),
        userId: m['other_user_id'].toString(),
        displayName: (m['display_name'] as String?)?.trim().isNotEmpty == true
            ? (m['display_name'] as String).trim()
            : 'Edible kullanıcısı',
        avatarUrl: m['avatar_url'] as String?,
        lastMessage: (m['last_message'] as String?) ?? '',
        lastMessageAt: DateTime.tryParse(m['last_message_at']?.toString() ?? ''),
        unreadCount: (m['unread_count'] as num?)?.toInt() ?? 0,
        isBlocked: m['is_blocked'] == true,
      );
}

class DirectMessage {
  const DirectMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    required this.readAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  factory DirectMessage.fromMap(Map<String, dynamic> m) => DirectMessage(
        id: m['id'].toString(),
        conversationId: m['conversation_id'].toString(),
        senderId: m['sender_id'].toString(),
        body: (m['body'] as String?) ?? '',
        createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
        readAt: DateTime.tryParse(m['read_at']?.toString() ?? ''),
      );
}

class MessagingService {
  SupabaseClient? get _client => SupabaseService.client;

  Future<List<ConversationSummary>> conversations() async {
    final client = _client;
    if (client == null) return const [];
    final rows = await client.rpc('get_my_conversations');
    return (rows as List)
        .whereType<Map>()
        .map((e) => ConversationSummary.fromMap(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<String> getOrCreateConversation(String otherUserId) async {
    final client = _client;
    if (client == null) throw StateError('Supabase bağlantısı hazır değil.');
    final result = await client.rpc('get_or_create_direct_conversation', params: {
      'p_other_user_id': otherUserId,
    });
    return result.toString();
  }

  Future<List<DirectMessage>> messages(String conversationId) async {
    final client = _client;
    if (client == null) return const [];
    final rows = await client
        .from('direct_messages')
        .select('id,conversation_id,sender_id,body,created_at,read_at')
        .eq('conversation_id', conversationId)
        .order('created_at');
    return (rows as List)
        .whereType<Map>()
        .map((e) => DirectMessage.fromMap(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Stream<List<Map<String, dynamic>>> messageStream(String conversationId) {
    final client = _client;
    if (client == null) return const Stream.empty();
    return client
        .from('direct_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at');
  }

  Future<DirectMessage?> send(String conversationId, String body) async {
    final client = _client;
    final text = body.trim();
    if (client == null) throw StateError('Supabase bağlantısı hazır değil.');
    if (text.isEmpty || text.length > 4000) return null;

    final result = await client.rpc('send_direct_message', params: {
      'p_conversation_id': conversationId,
      'p_body': text,
    });

    // The RPC returns the persisted message id. Return a local representation
    // immediately so the chat UI does not depend on a realtime round-trip or
    // a second SELECT before showing the sender's own message.
    final messageId = result?.toString();
    final currentUserId = client.auth.currentUser?.id;
    final message = (messageId != null &&
            messageId.isNotEmpty &&
            currentUserId != null)
        ? DirectMessage(
            id: messageId,
            conversationId: conversationId,
            senderId: currentUserId,
            body: text,
            createdAt: DateTime.now(),
            readAt: null,
          )
        : null;

    // Push delivery is best-effort. A notification failure must never make a
    // successfully persisted message look like it failed.
    await NotificationService.instance.sendMessageNotification(conversationId);
    return message;
  }

  Future<void> markRead(String conversationId) async {
    final client = _client;
    if (client == null) return;
    await client.rpc('mark_direct_messages_read', params: {
      'p_conversation_id': conversationId,
    });
  }

  Future<bool> isBlocked(String otherUserId) async {
    final client = _client;
    if (client == null) return false;
    final result = await client.rpc('is_user_blocked', params: {'p_other_user_id': otherUserId});
    return result == true;
  }

  Future<void> setBlocked(String otherUserId, bool blocked) async {
    final client = _client;
    if (client == null) throw StateError('Supabase bağlantısı hazır değil.');
    await client.rpc('set_user_block', params: {
      'p_other_user_id': otherUserId,
      'p_blocked': blocked,
    });
  }

  Future<void> reportUser({required String userId, required String reason, String? details}) async {
    final client = _client;
    if (client == null) throw StateError('Supabase bağlantısı hazır değil.');
    await client.rpc('report_user', params: {
      'p_reported_user_id': userId,
      'p_reason': reason,
      'p_details': details?.trim().isEmpty == true ? null : details?.trim(),
    });
  }
}
