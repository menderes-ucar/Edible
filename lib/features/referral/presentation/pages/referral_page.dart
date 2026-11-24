import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/config/share_config.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/referral_service.dart';

/// Invite friends: you both get 5 free AI trip plans.
class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  static const _service = ReferralService();
  static const _maxFriends = 10;

  final _codeController = TextEditingController();
  ReferralInfo? _info;
  bool _loading = true;
  bool _failed = false;
  bool _redeeming = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!context.read<AuthProvider>().isAuthenticated) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final info = await _service.getInfo();
      if (!mounted) return;
      setState(() {
        _info = info;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  Future<void> _redeem() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _redeeming) return;
    setState(() {
      _redeeming = true;
      _message = null;
    });

    final result = await _service.redeem(code);
    if (!mounted) return;

    final l10n = context.l10n;
    setState(() {
      _redeeming = false;
      _messageIsError = result != RedeemResult.ok;
      _message = switch (result) {
        RedeemResult.ok => l10n.text('referralOk'),
        RedeemResult.invalidCode => l10n.text('referralInvalid'),
        RedeemResult.ownCode => l10n.text('referralOwn'),
        RedeemResult.alreadyRedeemed => l10n.text('referralAlready'),
        RedeemResult.limitReached => l10n.text('referralLimit'),
        RedeemResult.failed => l10n.text('referralError'),
      };
    });

    if (result == RedeemResult.ok) {
      _codeController.clear();
      _load();
    }
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.text('referralCopied'))),
    );
  }

  Future<void> _share(BuildContext buttonContext, String code) async {
    final box = buttonContext.findRenderObject();
    Rect? origin;
    if (box is RenderBox && box.hasSize) {
      origin = box.localToGlobal(Offset.zero) & box.size;
    }

    final link = ShareConfig.appShareUrl;
    final text = buttonContext.l10n
        .text('referralShareText')
        .replaceAll('{code}', code);
    await Share.share(
      link == null ? text : '$text\n$link',
      sharePositionOrigin: origin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.text('referralTitle'))),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : !auth.isAuthenticated
                ? _message_(
                    context,
                    l10n.text('referralLoginRequired'),
                    actionLabel: l10n.text('signIn'),
                    onAction: () => context.push('/login?from=%2Finvite'),
                  )
                : _failed || _info == null
                    ? _message_(
                        context,
                        l10n.text('referralError'),
                        actionLabel: l10n.text('retry'),
                        onAction: _load,
                      )
                    : _content(context, _info!),
      ),
    );
  }

  Widget _message_(
    BuildContext context,
    String text, {
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, ReferralInfo info) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Icon(Icons.card_giftcard_rounded, size: 52, color: scheme.primary),
        const SizedBox(height: 12),
        Text(
          l10n.text('referralSubtitle'),
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.text('referralHowItWorks').replaceAll('{friends}', '$_maxFriends'),
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(l10n.text('referralYourCode'), style: textTheme.labelLarge),
              const SizedBox(height: 8),
              SelectableText(
                info.code,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _copy(info.code),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text(l10n.text('referralCopy')),
                  ),
                  Builder(
                    builder: (buttonContext) => FilledButton.icon(
                      onPressed: () => _share(buttonContext, info.code),
                      icon: const Icon(Icons.ios_share_rounded, size: 18),
                      label: Text(l10n.text('referralShare')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.text('referralCredits').replaceAll('{count}', '${info.credits}'),
                style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.text('referralCount').replaceAll('{count}', '${info.referrals}'),
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 26),
        Text(
          l10n.text('referralHaveCode'),
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _codeController,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: l10n.text('referralEnterCode'),
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _redeem(),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: _redeeming ? null : _redeem,
          child: _redeeming
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.text('referralRedeem')),
        ),
        if (_message != null) ...[
          const SizedBox(height: 10),
          Text(
            _message!,
            style: textTheme.bodyMedium?.copyWith(
              color: _messageIsError ? scheme.error : scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
