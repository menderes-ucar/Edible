import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_error_presenter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../subscription/domain/entities/subscription_entitlement.dart';
import '../../../subscription/presentation/widgets/premium_gate.dart';
import '../providers/offline_city_pack_provider.dart';

class OfflineCityPacksPage extends StatefulWidget {
  const OfflineCityPacksPage({super.key});

  @override
  State<OfflineCityPacksPage> createState() => _OfflineCityPacksPageState();
}

class _OfflineCityPacksPageState extends State<OfflineCityPacksPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!PremiumGate.allowOrOpenPaywall(
        context,
        PremiumFeature.offlineCityPacks,
      )) {
        return;
      }

      context.read<OfflineCityPackProvider>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OfflineCityPackProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('offlineCityPacks')),
      ),
      body: state.isLoading && state.packs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null && state.packs.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppErrorPresenter.message(
                            context,
                            state.errorMessage,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: state.refresh,
                          icon: const Icon(Icons.refresh),
                          label: Text(context.l10n.text('retry')),
                        ),
                      ],
                    ),
                  ),
                )
              : state.packs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                          context.l10n.text('offlinePacksEmpty'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                  onRefresh: state.refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.packs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final pack = state.packs[index];

                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.offline_pin),
                          ),
                          title: Text(
                            pack.cityName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          subtitle: Text(
                            '${pack.countryName} • ${pack.contentCount} '
                            '${context.l10n.text('offlineItems')}',
                          ),
                          trailing: state.isPending(
                            countryCode: pack.countryCode,
                            cityName: pack.cityName,
                            languageCode: pack.languageCode,
                          )
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : IconButton(
                                  tooltip: context.l10n.text('delete'),
                                  onPressed: () async {
                                    final ok = await state.delete(pack);
                                    if (!context.mounted || ok) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppErrorPresenter.message(
                                            context,
                                            state.errorMessage,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
