import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../settings/presentation/providers/locale_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionProvider>();
    final auth = context.watch<AuthProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFF2D2D2D),
      body: Stack(
        children: [
          Positioned(top: -110, right: -85, child: _Orb(size: 250, color: Colors.white.withValues(alpha: .10))),
          Positioned(top: 310, left: -130, child: _Orb(size: 240, color: AppColors.freshGreen.withValues(alpha: .18))),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.backgroundDeep.withValues(alpha: .94),
                foregroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
                title: Text(context.l10n.text('profile'), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 34),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ProfileHero(
                      user: user,
                      isGuest: auth.isGuest,
                      isPremium: subscription.isPremium,
                      onSignIn: auth.isGuest ? () => context.push(AppRoutes.login) : null,
                    ),
                    if (!auth.isGuest && user != null) ...[
                      const SizedBox(height: 12),
                      const SizedBox(height: 16),
                      _PersonalInfo(user: user),
                    ],
                    const SizedBox(height: 20),
                    _SectionLabel(text: context.l10n.text('profile')),
                    const SizedBox(height: 9),
                    _ActionTile(
                      icon: Icons.explore_rounded,
                      color: AppColors.primary,
                      title: context.l10n.text('visits'),
                      subtitle: context.l10n.text('visitedPlaces'),
                      onTap: () => context.push(AppRoutes.visits),
                    ),
                    const SizedBox(height: 9),
                    _ActionTile(
                      icon: Icons.luggage_rounded,
                      color: AppColors.orange,
                      title: context.l10n.text('myTrips'),
                      subtitle: context.l10n.text('myTripsSubtitle'),
                      onTap: () => context.push(AppRoutes.savedTrips),
                    ),
                    const SizedBox(height: 9),
                    _ActionTile(
                      icon: Icons.notifications_rounded,
                      color: AppColors.freshGreen,
                      title: context.l10n.text('notifications'),
                      subtitle: context.l10n.text('notificationCenterSubtitle'),
                      onTap: () => context.push(AppRoutes.notifications),
                    ),
                    const SizedBox(height: 18),
                    _SectionLabel(text: context.l10n.text('language')),
                    const SizedBox(height: 9),
                    _LanguageTile(localeProvider: localeProvider),
                    const SizedBox(height: 18),
                    if (!auth.isGuest) ...[
                      _ActionTile(
                        icon: Icons.logout_rounded,
                        color: AppColors.error,
                        title: context.l10n.text('signOut'),
                        subtitle: 'Hesabından güvenli şekilde çıkış yap',
                        showArrow: false,
                        onTap: auth.isLoading ? null : () async {
                          final ok = await auth.signOut();
                          if (!context.mounted || ok) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(auth.errorMessage ?? context.l10n.text('somethingWentWrong'))),
                          );
                        },
                      ),
                      const SizedBox(height: 9),
                      _ActionTile(
                        icon: Icons.delete_forever_rounded,
                        color: AppColors.error,
                        title: 'Hesabı sil',
                        subtitle: 'Hesabını ve kişisel verilerini kalıcı olarak sil',
                        showArrow: false,
                        onTap: auth.isLoading ? null : () => _confirmDeleteAccount(context, auth),
                      ),
                    ] else
                      _GuestAction(onTap: () => context.push(AppRoutes.login)),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDeleteAccount(BuildContext context, AuthProvider auth) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Hesabı sil?'),
      content: const Text(
        'Bu işlem hesabını, profil bilgilerini ve Edible üzerindeki kişisel verilerini kalıcı olarak siler. Bu işlem geri alınamaz.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Hesabı sil'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final ok = await auth.deleteAccount();
  if (!context.mounted) return;
  if (ok) {
    context.go(AppRoutes.login);
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(auth.errorMessage ?? 'Hesap silinemedi. Lütfen tekrar deneyin.')),
  );
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.user, required this.isGuest, required this.isPremium, this.onSignIn});
  final AppUser? user;
  final bool isGuest;
  final bool isPremium;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    final first = user?.firstName?.trim() ?? '';
    final last = user?.lastName?.trim() ?? '';
    final name = [first, last].where((e) => e.isNotEmpty).join(' ');
    final displayName = name.isNotEmpty ? name : (user?.displayName ?? context.l10n.text('profileGuest'));

    return Container(
      constraints: const BoxConstraints(minHeight: 204),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.darkNavy, AppColors.primaryDark, AppColors.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: AppColors.darkNavy.withValues(alpha: .25), blurRadius: 26, offset: const Offset(0, 13))],
      ),
      child: Stack(children: [
        Positioned(right: -42, top: -56, child: _HeroRing(size: 160)),
        Positioned(right: 72, bottom: -80, child: _HeroRing(size: 145)),
        Positioned(left: -60, bottom: -74, child: _HeroRing(size: 135)),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .13), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: .45), width: 2)),
                child: Icon(isGuest ? Icons.travel_explore_rounded : Icons.person_rounded, color: Colors.white, size: 37),
              ),
              const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(displayName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900, height: 1.02)),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(isPremium ? Icons.workspace_premium_rounded : Icons.explore_rounded, color: AppColors.orangeLight, size: 17),
                  const SizedBox(width: 5),
                  Text(isPremium ? 'Premium Explorer' : 'Explorer', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                ]),
              ])),
            ]),
            const SizedBox(height: 20),
            if (!isGuest && user != null) Row(children: [
              _HeroMeta(icon: Icons.cake_outlined, text: user!.age == null ? '-' : '${user!.age} yaş'),
              const SizedBox(width: 8),
              _HeroMeta(icon: Icons.location_on_outlined, text: (user!.hometown?.trim().isNotEmpty ?? false) ? user!.hometown!.trim() : '-'),
            ]) else if (onSignIn != null)
              Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: onSignIn, icon: const Icon(Icons.login_rounded, size: 17), label: Text(context.l10n.text('signIn')), style: TextButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.white.withValues(alpha: .12)))),
          ]),
        ),
      ]),
    );
  }
}

class _HeroRing extends StatelessWidget {
  const _HeroRing({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: .08), width: 2), color: Colors.white.withValues(alpha: .045)));
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .11), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: .12))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: Colors.white), const SizedBox(width: 5), Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))]),
  );
}

class _PersonalInfo extends StatelessWidget {
  const _PersonalInfo({required this.user});
  final AppUser user;

  String _gender(String? value) => switch (value) {
    'female' => 'Kadın',
    'male' => 'Erkek',
    'non_binary' => 'Non-binary',
    'prefer_not_to_say' => 'Belirtmek istemiyorum',
    _ => value?.trim().isNotEmpty == true ? value! : '-',
  };

  @override
  Widget build(BuildContext context) {
    final first = user.firstName?.trim() ?? '';
    final last = user.lastName?.trim() ?? '';
    final name = [first, last].where((e) => e.isNotEmpty).join(' ');
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surfaceMint,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.primary.withValues(alpha: .24), width: 1.2),
        boxShadow: [BoxShadow(color: AppColors.darkNavy.withValues(alpha: .07), blurRadius: 18, offset: const Offset(0, 7))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 43, height: 43, decoration: BoxDecoration(gradient: AppColors.gradientBrand, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.badge_rounded, color: Colors.white, size: 22)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.l10n.text('personalInfo'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            const Text('Profil bilgilerin', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ])),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _InfoCell(icon: Icons.person_outline_rounded, label: 'Ad Soyad', value: name.isEmpty ? '-' : name)),
          const SizedBox(width: 9),
          Expanded(child: _InfoCell(icon: Icons.cake_outlined, label: 'Yaş', value: user.age?.toString() ?? '-')),
        ]),
        const SizedBox(height: 9),
        Row(children: [
          Expanded(child: _InfoCell(icon: Icons.location_on_outlined, label: 'Nereli', value: user.hometown?.trim().isNotEmpty == true ? user.hometown!.trim() : '-')),
          const SizedBox(width: 9),
          Expanded(child: _InfoCell(icon: Icons.wc_outlined, label: 'Cinsiyet', value: _gender(user.gender))),
        ]),
      ]),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({required this.icon, required this.label, required this.value});
  final IconData icon; final String label; final String value;
  @override
  Widget build(BuildContext context) => Container(
    height: 82,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(color: AppColors.surfaceStrong.withValues(alpha: .80), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.primary.withValues(alpha: .10))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 16, color: AppColors.primaryDark), const SizedBox(width: 5), Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textMuted)))]),
      const SizedBox(height: 8),
      Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
    ]),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary));
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap, this.showArrow = true});
  final IconData icon; final Color color; final String title; final String subtitle; final VoidCallback? onTap; final bool showArrow;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(23),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: AppColors.surfaceStrong, borderRadius: BorderRadius.circular(23), border: Border.all(color: color.withValues(alpha: .24)), boxShadow: [BoxShadow(color: AppColors.darkNavy.withValues(alpha: .055), blurRadius: 12, offset: const Offset(0, 5))]),
        child: Row(children: [
          Container(width: 51, height: 51, decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(17)), child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary)), const SizedBox(height: 3), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600))])),
          if (showArrow) Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withValues(alpha: .13), shape: BoxShape.circle), child: Icon(Icons.arrow_forward_rounded, size: 17, color: color)),
        ]),
      ),
    ),
  );
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.localeProvider});
  final LocaleProvider localeProvider;
  @override
  Widget build(BuildContext context) {
    final current = AppLanguage.fromCode(localeProvider.locale.languageCode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(color: AppColors.surfaceStrong, borderRadius: BorderRadius.circular(23), border: Border.all(color: AppColors.primary.withValues(alpha: .18))),
      child: Row(children: [
        Container(width: 49, height: 49, decoration: BoxDecoration(gradient: AppColors.gradientBrand, borderRadius: BorderRadius.circular(17)), child: const Icon(Icons.translate_rounded, color: Colors.white)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.l10n.text('language'), style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w700)), Text(current?.nativeName ?? localeProvider.locale.languageCode.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary))])),
        DropdownButtonHideUnderline(child: DropdownButton<String>(value: localeProvider.locale.languageCode, borderRadius: BorderRadius.circular(16), items: LocaleProvider.availableLocales.map((locale) { final language = AppLanguage.fromCode(locale.languageCode); return DropdownMenuItem(value: locale.languageCode, child: Text(language?.nativeName ?? locale.languageCode.toUpperCase())); }).toList(), onChanged: (value) { if (value != null) localeProvider.setLocale(Locale(value)); })),
      ]),
    );
  }
}

class _GuestAction extends StatelessWidget {
  const _GuestAction({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: AppColors.surfaceStrong, borderRadius: BorderRadius.circular(23), border: Border.all(color: AppColors.primary.withValues(alpha: .20))),
    child: Row(children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .14), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.login_rounded, color: AppColors.primaryDark)),
      const SizedBox(width: 11),
      Expanded(child: Text(context.l10n.text('signIn'), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary))),
      FilledButton(onPressed: onTap, child: Text(context.l10n.text('signIn'))),
    ]),
  );
}
