import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/messaging_service.dart';
import '../../../profile/presentation/pages/public_profile_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  static const route = '/messages';

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _service = MessagingService();
  late Future<List<ConversationSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.conversations();
  }

  Future<void> _reload() async {
    final future = _service.conversations();
    if (!mounted) return;
    setState(() {
      _future = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.text('messages'))),
        body: Center(
          child: FilledButton(
            onPressed: () => context.push('/login?from=%2Fmessages'),
            child: Text(context.l10n.text('signIn')),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('messages'), style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: FutureBuilder<List<ConversationSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(context.l10n.text('noResults')));
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.forum_outlined, size: 54, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 14),
                  Text(context.l10n.text('messagesEmpty'), textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ]),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final c = items[i];
                return Card(
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: _Avatar(url: c.avatarUrl),
                    title: Row(children: [
                      Expanded(child: Text(c.displayName, style: const TextStyle(fontWeight: FontWeight.w800))),
                      if (c.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(20)),
                          child: Text('${c.unreadCount}', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w900)),
                        ),
                    ]),
                    subtitle: Text(c.lastMessage.isEmpty ? context.l10n.text('startConversation') : c.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () async {
                      await context.push('${ChatPage.route}/${c.userId}');
                      if (mounted) await _reload();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({required this.userId, super.key});
  static const route = '/messages/chat';
  final String userId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _service = MessagingService();
  final _controller = TextEditingController();
  late Future<String> _conversationFuture;
  bool _sending = false;
  bool _blocked = false;
  String _name = 'Edible kullanıcısı';
  String? _avatar;
  List<DirectMessage> _messages = const [];

  @override
  void initState() {
    super.initState();
    _conversationFuture = _prepare();
  }

  Future<String> _prepare() async {
    final profile = await SupabaseService.client?.rpc('get_public_profile', params: {'p_user_id': widget.userId});
    if (profile is List && profile.isNotEmpty && mounted) {
      final p = Map<String, dynamic>.from(profile.first as Map);
      setState(() {
        _name = (p['display_name'] as String?)?.trim().isNotEmpty == true ? p['display_name'] as String : _name;
        _avatar = p['avatar_url'] as String?;
      });
    }
    _blocked = await _service.isBlocked(widget.userId);
    final conversationId = await _service.getOrCreateConversation(widget.userId);
    final initialMessages = await _service.messages(conversationId);
    if (mounted) {
      setState(() => _messages = initialMessages);
    }
    return conversationId;
  }

  Future<void> _send(String conversationId) async {
    if (_sending || _blocked) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final sentMessage = await _service.send(conversationId, text);
      _controller.clear();
      if (sentMessage != null && mounted) {
        setState(() {
          final exists = _messages.any((m) => m.id == sentMessage.id);
          if (!exists) {
            _messages = <DirectMessage>[..._messages, sentMessage];
          }
        });
      }
      // Refresh only as a reconciliation step. If RLS/realtime is briefly
      // behind, never replace a populated local list with an empty result.
      try {
        final refreshedMessages = await _service.messages(conversationId);
        if (mounted && refreshedMessages.isNotEmpty) {
          setState(() {
            final merged = <String, DirectMessage>{
              for (final message in _messages) message.id: message,
              for (final message in refreshedMessages) message.id: message,
            };
            final sorted = merged.values.toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
            _messages = sorted;
          });
        }
      } catch (_) {
        // The persisted message is already visible locally.
      }
      await _service.markRead(conversationId);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.text('actionFailed'))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _safetyMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.person_outline), title: Text(context.l10n.text('viewProfile')), onTap: () => Navigator.pop(context, 'profile')),
        ListTile(leading: Icon(_blocked ? Icons.lock_open_outlined : Icons.block_outlined), title: Text(_blocked ? context.l10n.text('unblockUser') : context.l10n.text('blockUser')), onTap: () => Navigator.pop(context, _blocked ? 'unblock' : 'block')),
        ListTile(leading: const Icon(Icons.flag_outlined), title: Text(context.l10n.text('reportUser')), onTap: () => Navigator.pop(context, 'report')),
      ])),
    );
    if (!mounted || action == null) return;
    if (action == 'profile') {
      context.push('${PublicProfilePage.routePrefix}/${widget.userId}');
      return;
    }
    if (action == 'block' || action == 'unblock') {
      final next = action == 'block';
      try {
        await _service.setBlocked(widget.userId, next);
        if (mounted) setState(() => _blocked = next);
      } catch (_) {}
      return;
    }
    if (action == 'report') await _report();
  }

  Future<void> _report() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(context.l10n.text('reportUser')),
        children: [
          for (final r in ['Spam', 'Harassment', 'Inappropriate content', 'Other'])
            SimpleDialogOption(onPressed: () => Navigator.pop(context, r), child: Text(r)),
        ],
      ),
    );
    if (reason == null) return;
    try {
      await _service.reportUser(userId: widget.userId, reason: reason);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.text('reportSent'))));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [_Avatar(url: _avatar, radius: 18), const SizedBox(width: 10), Expanded(child: Text(_name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)))]),
        actions: [IconButton(onPressed: _safetyMenu, icon: const Icon(Icons.more_vert_rounded))],
      ),
      body: FutureBuilder<String>(
        future: _conversationFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final id = snapshot.data!;
          return Column(children: [
            Expanded(child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.messageStream(id),
              builder: (context, s) {
                final streamedMessages = (s.data ?? const [])
                    .map(DirectMessage.fromMap)
                    .toList(growable: false);
                final merged = <String, DirectMessage>{
                  for (final message in _messages) message.id: message,
                  for (final message in streamedMessages) message.id: message,
                };
                final messages = merged.values.toList()
                  ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
                if (messages.isEmpty) return Center(child: Text(context.l10n.text('startConversation')));
                WidgetsBinding.instance.addPostFrameCallback((_) => _service.markRead(id));
                return ListView.builder(
                  reverse: false,
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[i];
                    final mine = m.senderId == context.read<AuthProvider>().user!.id;
                    return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: mine ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(18)),
                      child: Text(m.body, style: TextStyle(color: mine ? Theme.of(context).colorScheme.onPrimary : null)),
                    ));
                  },
                );
              },
            )),
            if (_blocked) Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 12), child: Text(context.l10n.text('userBlocked'), textAlign: TextAlign.center)),
            SafeArea(top: false, child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(children: [
                Expanded(child: TextField(controller: _controller, enabled: !_blocked, maxLength: 4000, minLines: 1, maxLines: 5, decoration: InputDecoration(hintText: context.l10n.text('messageHint'), counterText: '', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)))),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: snapshot.hasData ? () => _send(id) : null, icon: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded)),
              ]),
            )),
          ]);
        },
      ),
    );
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url, this.radius = 26});
  final String? url;
  final double radius;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundImage: url?.trim().isNotEmpty == true ? NetworkImage(url!) : null,
    child: url?.trim().isNotEmpty == true ? null : Icon(Icons.person_outline, size: radius),
  );
}
