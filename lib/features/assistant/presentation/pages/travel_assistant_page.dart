import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/error/app_error_presenter.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../referral/data/referral_service.dart';
import '../../../subscription/domain/entities/subscription_entitlement.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../../subscription/presentation/widgets/premium_gate.dart';
import '../../domain/entities/travel_assistant_response.dart';
import '../providers/travel_assistant_provider.dart';

class TravelAssistantPage extends StatefulWidget {
  const TravelAssistantPage({
    this.defaultCityName,
    super.key,
  });

  final String? defaultCityName;

  @override
  State<TravelAssistantPage> createState() => _TravelAssistantPageState();
}

class _TravelAssistantPageState extends State<TravelAssistantPage> {
  static const _referral = ReferralService();

  final _controller = TextEditingController();
  bool _prefilled = false;

  /// Free AI plans left (signed-in, non-premium users only).
  int? _credits;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Needs the localization context, so it cannot run in initState.
    if (_prefilled) return;
    _prefilled = true;
    final city = widget.defaultCityName;
    if (city != null && city.trim().isNotEmpty) {
      _controller.text =
          context.l10n.text('assistantPrefill').replaceAll('{city}', city);
    }
    unawaited(_refreshCredits());
  }

  Future<void> _refreshCredits() async {
    final canUsePremium = context
        .read<SubscriptionProvider>()
        .canUse(PremiumFeature.travelAssistant);
    if (canUsePremium || !context.read<AuthProvider>().isAuthenticated) {
      if (_credits != null && mounted) setState(() => _credits = null);
      return;
    }
    try {
      final access = await _referral.getAssistantAccess();
      if (!mounted) return;
      setState(() => _credits = access.premium ? null : access.credits);
    } catch (_) {
      // Optional hint; the gate re-checks on every request.
    }
  }

  /// Premium users pass; everyone else needs a free credit earned by inviting
  /// friends. The server enforces the same rule, this only avoids a dead end.
  Future<bool> _canUseAssistant() async {
    final premium = context
        .read<SubscriptionProvider>()
        .canUse(PremiumFeature.travelAssistant);
    if (premium) return true;

    if (context.read<AuthProvider>().isAuthenticated) {
      try {
        final access = await _referral.getAssistantAccess();
        if (!mounted) return false;
        setState(() => _credits = access.premium ? null : access.credits);
        if (access.premium || access.credits > 0) return true;
      } catch (_) {
        // Fall through to the "no free plans" sheet.
      }
    }

    if (!mounted) return false;
    await _showNoCreditsSheet();
    return false;
  }

  Future<void> _showNoCreditsSheet() {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.text('assistantNoCreditsTitle'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(l10n.text('assistantNoCreditsBody')),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push(AppRoutes.invite);
                  },
                  icon: const Icon(Icons.card_giftcard_rounded),
                  label: Text(l10n.text('referralTitle')),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    PremiumGate.allowOrOpenPaywall(
                      context,
                      PremiumFeature.travelAssistant,
                    );
                  },
                  child: Text(l10n.text('ediblePremium')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    if (!await _canUseAssistant()) return;
    if (!mounted) return;

    await context.read<TravelAssistantProvider>().ask(
          message: _controller.text,
          languageCode: Localizations.localeOf(context).languageCode,
          defaultCityName: widget.defaultCityName,
        );

    if (mounted) unawaited(_refreshCredits());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TravelAssistantProvider>();
    final response = state.response;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('travelAssistant')),
        actions: [
          if (response != null)
            IconButton(
              onPressed: state.clear,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            context.l10n.text('assistantHeadline'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(context.l10n.text('assistantSubtitle')),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: context.l10n.text('assistantHint'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.l10n.text('assistantPrivacyNote'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.35,
                      ),
                ),
              ),
            ],
          ),
          if (_credits != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.card_giftcard_rounded, size: 16, color: AppColors.orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.l10n
                        .text('referralCredits')
                        .replaceAll('{count}', '$_credits'),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.invite),
                  child: Text(context.l10n.text('referralTitle')),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: state.isLoading ? null : _ask,
            icon: state.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(context.l10n.text('buildMyRoute')),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              AppErrorPresenter.message(context, state.errorMessage),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          if (response != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      response.summary,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${response.cityName} • ${response.hours} ${context.l10n.text('hours')}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            _AssistantNotice(source: response.source),
            const SizedBox(height: 14),
            ...response.stops.map(
              (stop) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      stop.timeLabel,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  title: Text(
                    stop.content.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(stop.reason),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    AppRoutes.contentDetail(stop.content.id),
                    extra: stop.content,
                  ),
                ),
              ),
            ),
            if (response.tips.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                context.l10n.text('assistantTips'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              ...response.tips.map(
                (tip) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.lightbulb_outline),
                    title: Text(tip),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _AssistantNotice extends StatelessWidget {
  const _AssistantNotice({required this.source});

  final TravelAssistantSource source;

  @override
  Widget build(BuildContext context) {
    final key = switch (source) {
      TravelAssistantSource.ai => 'assistantAiNotice',
      TravelAssistantSource.basic => 'assistantBasicNotice',
      TravelAssistantSource.basicQuotaReached => 'assistantQuotaReached',
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          source == TravelAssistantSource.ai
              ? Icons.auto_awesome
              : Icons.info_outline_rounded,
          size: 16,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.l10n.text(key),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}
