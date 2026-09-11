import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../messaging/data/messaging_service.dart';
import '../../../messaging/presentation/pages/messages_page.dart';

class PublicProfilePage extends StatefulWidget {
  const PublicProfilePage({required this.userId, super.key});

  static const routePrefix = '/public-profile';
  final String userId;

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  late Future<_PublicProfile?> _future;
  final _messaging = MessagingService();
  bool _blocked = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_PublicProfile?> _load() async {
    final client = SupabaseService.client;
    if (client == null) return null;
    final profileRows = await client.rpc('get_public_profile', params: {'p_user_id': widget.userId});
    if (profileRows is! List || profileRows.isEmpty) return null;
    final detailRows = await client.rpc('get_public_profile_details', params: {'p_user_id': widget.userId});
    final visitsRows = await client.rpc('get_public_profile_visits', params: {'p_user_id': widget.userId});
    _blocked = await _messaging.isBlocked(widget.userId);
    final base = Map<String, dynamic>.from(profileRows.first as Map);
    final details = detailRows is List && detailRows.isNotEmpty
        ? Map<String, dynamic>.from(detailRows.first as Map)
        : <String, dynamic>{};
    return _PublicProfile.fromMaps(
      {...base, ...details},
      visitsRows is List ? visitsRows.whereType<Map>().map(Map<String, dynamic>.from).toList() : const [],
    );
  }

  Future<void> _message() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      context.push('/login?from=${Uri.encodeComponent('${MessagesPage.route}/${widget.userId}')}');
      return;
    }
    if (_blocked) return;
    await context.push('${ChatPage.route}/${widget.userId}');
  }

  Future<void> _toggleBlock() async {
    final next = !_blocked;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(next ? context.l10n.text('blockUser') : context.l10n.text('unblockUser')),
        content: Text(next ? context.l10n.text('blockConfirm') : context.l10n.text('unblockConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.text('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(next ? context.l10n.text('blockUser') : context.l10n.text('unblockUser'))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await _messaging.setBlocked(widget.userId, next);
      if (mounted) setState(() { _blocked = next; _busy = false; });
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
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
      await _messaging.reportUser(userId: widget.userId, reason: reason);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.text('reportSent'))));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final currentId = context.watch<AuthProvider>().user?.id;
    final isSelf = currentId == widget.userId;
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D2D),
      appBar: AppBar(
        title: Text(context.l10n.text('profile'), style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (!isSelf) PopupMenuButton<String>(
            onSelected: (v) { if (v == 'block') _toggleBlock(); if (v == 'report') _report(); },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'block', child: ListTile(leading: Icon(_blocked ? Icons.lock_open_outlined : Icons.block_outlined), title: Text(_blocked ? context.l10n.text('unblockUser') : context.l10n.text('blockUser')))),
              PopupMenuItem(value: 'report', child: ListTile(leading: const Icon(Icons.flag_outlined), title: Text(context.l10n.text('reportUser')))),
            ],
          ),
        ],
      ),
      body: FutureBuilder<_PublicProfile?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final profile = snapshot.data;
          if (snapshot.hasError || profile == null) return Center(child: Text(context.l10n.text('profileNotFound')));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientTurquoiseToGreen,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(children: [
                  Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white54, width: 2)), child: _Avatar(url: profile.avatarUrl, radius: 48)),
                  const SizedBox(height: 12),
                  Text(profile.displayName.isEmpty ? context.l10n.text('appUser') : profile.displayName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _Stat(value: '${profile.visitCount}', label: context.l10n.text('visits'), light: true),
                    Container(height: 32, width: 1, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 28)),
                    _Stat(value: '${profile.visits.length}', label: context.l10n.text('travelDays'), light: true),
                  ]),
                ]),
              ),
              if (!isSelf) ...[
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: FilledButton.icon(onPressed: _blocked || _busy ? null : _message, icon: const Icon(Icons.chat_bubble_outline_rounded), label: Text(context.l10n.text('sendMessage')))),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(onPressed: _busy ? null : _toggleBlock, icon: Icon(_blocked ? Icons.lock_open_outlined : Icons.block_outlined), tooltip: _blocked ? context.l10n.text('unblockUser') : context.l10n.text('blockUser')),
                ]),
              ],
              if (profile.firstName != null || profile.lastName != null || profile.age != null || profile.hometown != null || profile.gender != null) ...[
                const SizedBox(height: 18),
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.text('personalInfo'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        if (profile.firstName != null || profile.lastName != null) _PublicInfoRow(icon: Icons.person_outline, label: 'Ad Soyad', value: [profile.firstName, profile.lastName].whereType<String>().where((e) => e.isNotEmpty).join(' ')),
                        if (profile.age != null) _PublicInfoRow(icon: Icons.cake_outlined, label: 'Yaş', value: '${profile.age}'),
                        if (profile.hometown != null) _PublicInfoRow(icon: Icons.location_on_outlined, label: 'Nereli', value: profile.hometown!),
                        if (profile.gender != null) _PublicInfoRow(icon: Icons.wc_outlined, label: 'Cinsiyet', value: _genderLabel(profile.gender!)),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Text(context.l10n.text('visits'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              if (profile.visits.isEmpty)
                Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(22), child: Text(context.l10n.text('noPublicVisits'))))
              else
                ...profile.visits.map((visit) => Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.location_on_outlined)),
                    title: Text(visit['city_name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(visit['country_code'] as String? ?? ''),
                    trailing: Text(visit['visit_day'] as String? ?? ''),
                  ),
                )),
            ],
          );
        },
      ),
    );
  }
}

class _PublicProfile {
  const _PublicProfile({required this.displayName, required this.avatarUrl, required this.visitCount, required this.visits, this.firstName, this.lastName, this.age, this.hometown, this.gender});
  final String displayName;
  final String? avatarUrl;
  final int visitCount;
  final List<Map<String, dynamic>> visits;
  final String? firstName;
  final String? lastName;
  final int? age;
  final String? hometown;
  final String? gender;
  factory _PublicProfile.fromMaps(Map<String, dynamic> profile, List<Map<String, dynamic>> visits) => _PublicProfile(
    displayName: (profile['display_name'] as String?)?.trim() ?? '',
    avatarUrl: profile['avatar_url'] as String?,
    visitCount: (profile['visit_count'] as num?)?.toInt() ?? 0,
    visits: visits,
    firstName: (profile['first_name'] as String?)?.trim(),
    lastName: (profile['last_name'] as String?)?.trim(),
    age: (profile['age'] as num?)?.toInt(),
    hometown: (profile['hometown'] as String?)?.trim(),
    gender: (profile['gender'] as String?)?.trim(),
  );
}

String _genderLabel(String value) {
  switch (value) {
    case 'female': return 'Kadın';
    case 'male': return 'Erkek';
    case 'non_binary': return 'Non-binary';
    case 'prefer_not_to_say': return 'Belirtmek istemiyorum';
    default: return value;
  }
}

class _PublicInfoRow extends StatelessWidget {
  const _PublicInfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [Icon(icon, size: 19), const SizedBox(width: 10), SizedBox(width: 78, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))), Expanded(child: Text(value, textAlign: TextAlign.end))]),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url, this.radius = 26});
  final String? url;
  final double radius;
  @override
  Widget build(BuildContext context) => CircleAvatar(radius: radius, backgroundImage: url?.trim().isNotEmpty == true ? NetworkImage(url!) : null, child: url?.trim().isNotEmpty == true ? null : Icon(Icons.person_outline, size: radius));
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.light = false});
  final String value; final String label; final bool light;
  @override
  Widget build(BuildContext context) => Column(children: [Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: light ? Colors.white : null)), Text(label, style: TextStyle(color: light ? Colors.white70 : Colors.grey.shade600))]);
}
