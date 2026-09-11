import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_error_presenter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/purchase_option.dart';
import '../providers/purchase_provider.dart';
import '../providers/subscription_provider.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({
    this.featureName,
    super.key,
  });

  final String? featureName;

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  String? _authIdentity;
  bool _loginRedirectScheduled = false;

  String get _returnLocation {
    final featureName = widget.featureName?.trim();
    return featureName == null || featureName.isEmpty
        ? AppRoutes.paywall
        : '${AppRoutes.paywall}'
            '?feature=${Uri.encodeQueryComponent(featureName)}';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = context.watch<AuthProvider>();
    final identity = auth.user?.id;

    if (auth.isGuest || identity == null) {
      _authIdentity = null;

      if (_loginRedirectScheduled) {
        return;
      }
      _loginRedirectScheduled = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final currentAuth = context.read<AuthProvider>();
        if (!currentAuth.isGuest) {
          _loginRedirectScheduled = false;
          return;
        }

        context.push(AppRoutes.loginFor(_returnLocation)).whenComplete(() {
          if (!mounted) return;
          _loginRedirectScheduled = false;
        });
      });
      return;
    }

    _loginRedirectScheduled = false;
    if (_authIdentity == identity) {
      return;
    }

    _authIdentity = identity;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final currentAuth = context.read<AuthProvider>();
      if (!currentAuth.isAuthenticated ||
          currentAuth.user?.id != identity) {
        return;
      }

      if (!context.read<SubscriptionProvider>().isPremium) {
        context.read<PurchaseProvider>().loadOptions();
      }
    });
  }

  Future<void> _purchase(PurchaseOption option) async {
    final success =
        await context.read<PurchaseProvider>().purchase(option);

    if (!mounted) return;

    final purchases = context.read<PurchaseProvider>();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.text('premiumActivated')),
        ),
      );
      context.pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          purchases.errorMessage == null
              ? context.l10n.text('somethingWentWrong')
              : AppErrorPresenter.message(
                  context,
                  purchases.errorMessage,
                ),
        ),
      ),
    );
  }

  Future<void> _restore() async {
    final success = await context.read<PurchaseProvider>().restore();

    if (!mounted) return;

    final purchases = context.read<PurchaseProvider>();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? context.l10n.text('premiumRestored')
              : purchases.errorMessage == null
                  ? context.l10n.text('noPurchaseFound')
                  : AppErrorPresenter.message(
                      context,
                      purchases.errorMessage,
                    ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionProvider>();
    final purchases = context.watch<PurchaseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('ediblePremium')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          const Icon(Icons.workspace_premium_outlined, size: 72),
          const SizedBox(height: 18),
          Text(
            subscription.isPremium
                ? context.l10n.text('premiumActive')
                : context.l10n.text('premiumHeadline'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subscription.isPremium
                ? context.l10n.text('premiumActiveSubtitle')
                : context.l10n.text('premiumSubtitle'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _Benefit(
            icon: Icons.download_for_offline_outlined,
            title: context.l10n.text('premiumOffline'),
          ),
          _Benefit(
            icon: Icons.route_outlined,
            title: context.l10n.text('premiumPlanner'),
          ),
          _Benefit(
            icon: Icons.auto_awesome,
            title: context.l10n.text('premiumAssistant'),
          ),
          const SizedBox(height: 20),
          if (purchases.errorMessage != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Text(
                      AppErrorPresenter.message(
                        context,
                        purchases.errorMessage,
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    if (purchases.options.isEmpty) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: purchases.isLoading
                            ? null
                            : purchases.loadOptions,
                        icon: const Icon(Icons.refresh),
                        label: Text(context.l10n.text('retry')),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (!subscription.isPremium) ...[
            if (purchases.isLoading && purchases.options.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (purchases.options.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    context.l10n.text('noOfferings'),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...purchases.options.map(
                (option) => _PurchaseCard(
                  option: option,
                  disabled: purchases.isLoading,
                  onPressed: () => _purchase(option),
                ),
              ),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: purchases.isLoading ? null : _restore,
            child: Text(context.l10n.text('restoreSubscription')),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.text('purchaseTermsNote'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({
    required this.option,
    required this.disabled,
    required this.onPressed,
  });

  final PurchaseOption option;
  final bool disabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    option.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: disabled ? null : onPressed,
              child: Text(option.priceText),
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        trailing: const Icon(Icons.check_circle_outline),
      ),
    );
  }
}
